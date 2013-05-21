#include "lua/xml.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifdef ENABLE_LIBXML
#include <libxml/parser.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

static int lbox_push_xmlnode(struct lua_State *L,
	xmlNodePtr node, int was_alloc);

static int
lbox_xmldocnode_tostring(struct lua_State *L, xmlDocPtr doc, xmlNodePtr node)
{
	xmlBufferPtr buffer = xmlBufferCreate();
	xmlNodeDump( buffer, doc, node, 0, 0);
	const char *ret = (const char *)xmlBufferContent(buffer);
	if (ret == NULL) {
		lua_pushnil(L);
	} else {
		lua_pushstring(L, ret);
	}
	xmlBufferFree( buffer );
	return 1;
}


static xmlNodePtr
lua_toxmlnode(struct lua_State *L, int index)
{
	if (!lua_isuserdata(L, index))
		luaL_error(L, "argument %d isn't XML node", index);
	xmlNodePtr node = *(void **) lua_touserdata(L, index);
	return node;
}

static int
lbox_xmlnode_tostring(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	if (node->type != XML_DOCUMENT_NODE)
		return lbox_xmldocnode_tostring(L, node->doc, node);
	return lbox_xmldocnode_tostring(L, (xmlDocPtr)node, node->children);
}


static int
lbox_xmlnode_xpath(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	const char *path = lua_tostring(L, 2);

	xmlXPathContextPtr xpathCtx;
	xmlXPathObjectPtr xpathObj;

	xpathCtx = xmlXPathNewContext(node->doc);
	if (xpathCtx == NULL)
		luaL_error(L, "unable to create new XPath context");
	xpathCtx->node = node;

	xpathObj = xmlXPathEvalExpression((const xmlChar *)path, xpathCtx);
	if (xpathObj == 0) {
		xmlXPathFreeContext(xpathCtx);
		luaL_error(L, "unable to evaluate xpath expression '%s'", path);
	}


	int ret = 0;
	typeof(xpathObj->nodesetval) nodes = xpathObj->nodesetval;
	if (nodes && nodes->nodeNr) {
		for (int i = 0; i < nodes->nodeNr; i++) {
			lbox_push_xmlnode(L, nodes->nodeTab[i], 0);
			ret++;
		}
	}


	xmlXPathFreeObject(xpathObj);
	xmlXPathFreeContext(xpathCtx);

	return ret;
}

static int
lbox_xmlnode_attribute(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	const char *attr = lua_tostring(L, 2);

	xmlChar *v = xmlGetProp(node, (const xmlChar *)attr);

	/* use want to remove attribute */
	if (lua_gettop(L) > 2) {
		if (lua_isnil(L, 3)) {
			xmlUnsetProp(node, (const xmlChar *)attr);
		} else {
			const char *value = lua_tostring(L, 3);
			xmlSetProp(node, (const xmlChar *)attr,
				(const xmlChar *)value);
		}
	}

	/* get attribute */
	if (v) {
		lua_pushstring(L, (const char *)v);
		xmlFree(v);
	} else {
		lua_pushnil(L);
	}

	return 1;
}

static int
lbox_xmlnode_parent(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	if (node->parent)
		lbox_push_xmlnode(L, node->parent, 0);
	else
		lua_pushnil(L);
	return 1;
}

static int
lbox_xmlnode_append(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	xmlNodePtr child = lua_toxmlnode(L, 2);

	if (child->next || child->prev || child->parent)
		luaL_error(L, "child is already inserted in tree");

	if (xmlAddChild(node, child)) {

		/* inserted node needn't to be freed by lua gc */
		luaL_getmetatable(L, "box.xml.lib_nogc");
		lua_setmetatable(L, 2);

		lua_pushvalue(L, 2);

	} else {
		lua_pushnil(L);
	}
	return 1;
}

static int
lbox_xmlnode_gc(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	if (node->type == XML_DOCUMENT_NODE)
		xmlFreeDoc((xmlDocPtr)node);
	else
		xmlFreeNode(node);
	return 0;
}

static int
lbox_xmlnode_remove(struct lua_State *L)
{
	xmlNodePtr child = lua_toxmlnode(L, 1);

	if (child->parent == child || !child->parent ) {
		luaL_error(L, "The node isn't a child node");
		return 1;
	}

	xmlUnlinkNode(child);

	/* inserted node needn't to be freed by lua gc */
	luaL_getmetatable(L, "box.xml.lib_gc");
	lua_setmetatable(L, 1);

	lua_pushvalue(L, 1);

	return 1;
}


static int
lbox_xmlnode_text(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);

	if (lua_gettop(L) > 1) {
		xmlNodeAddContent(node, (const xmlChar *)lua_tostring(L, 2));
	}

	xmlChar *str = xmlXPathCastNodeToString(node);
	lua_pushstring(L, (const char *)str);
	xmlFree(str);
	return 1;
}


static int
lbox_xmlnode_clone(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	xmlNodePtr clone = xmlCopyNode(node, 1);
	lbox_push_xmlnode(L, clone, 1);
	return 1;
}


static int
lbox_push_xmlnode(struct lua_State *L, xmlNodePtr node, int was_alloc)
{

	void **ptr = lua_newuserdata(L, sizeof(void *));
	*ptr = node;

	if (was_alloc)
		luaL_getmetatable(L, "box.xml.lib_gc");
	else
		luaL_getmetatable(L, "box.xml.lib_nogc");
	lua_setmetatable(L, -2);

	return 1;
}


static int
lbox_xml_element(struct lua_State *L)
{
	size_t len;
	const char *name = lua_tolstring(L, 1, &len);
	xmlNodePtr newnode = xmlNewNode(NULL, (const xmlChar *)name);
	lbox_push_xmlnode(L, newnode, 1);

	return 1;
}

static int
lbox_xml_load(struct lua_State *L)
{
	if (lua_gettop(L) < 1)
		luaL_error(L, "box.xml.load: wrong arguments");
	size_t len;
	const char *xml = lua_tolstring(L, 1, &len);

	xmlDocPtr doc = xmlParseMemory(xml, len);
	if (doc == NULL) {
		return 0;
	}
	lbox_push_xmlnode(L, (xmlNodePtr)doc, 1);

	return 1;
}


static int
lbox_xmlnode_replace(struct lua_State *L)
{
	xmlNodePtr old = lua_toxmlnode(L, 1);
	xmlNodePtr new = lua_toxmlnode(L, 2);

	if (!old->parent)
		luaL_error(L, "Can't replace not-inserted node");
	if (new->parent)
		luaL_error(L, "Can't insert inserted node");

	if (xmlReplaceNode(old, new)) {
		/* inserted node needn't to be freed by lua gc */
		luaL_getmetatable(L, "box.xml.lib_nogc");
		lua_setmetatable(L, 2);

		lua_pushvalue(L, 2);

		/* old element can be destroyed */
		xmlUnlinkNode(old);
		luaL_getmetatable(L, "box.xml.lib_gc");
		lua_setmetatable(L, 1);

	} else {
		lua_pushnil(L);
	}
	return 1;
}

int
tarantool_lua_xml_init(struct lua_State *L)
{
	static const struct luaL_reg xml_meta[] = {
		{"load",	lbox_xml_load			},
		{"element",	lbox_xml_element		},
		{NULL, NULL}
	};
	lua_getfield(L, LUA_GLOBALSINDEX, "box");

	lua_pushstring(L, "xml");
	lua_newtable(L);
	luaL_register(L, NULL, xml_meta);

	lua_pushstring(L, "enabled");
	lua_pushboolean(L, 1);
	lua_rawset(L, -3);

	lua_settable(L, -3);
	lua_pop(L, 1);

	static const struct luaL_reg node_methods[] = {
		{ "xpath",	lbox_xmlnode_xpath	},
		{ "attribute",	lbox_xmlnode_attribute	},
		{ "parent",	lbox_xmlnode_parent	},
		{ "append",	lbox_xmlnode_append	},
		{ "clone",	lbox_xmlnode_clone	},
		{ "remove",	lbox_xmlnode_remove	},
		{ "replace",	lbox_xmlnode_replace	},
		{ "text",	lbox_xmlnode_text	},
		{ NULL, NULL }
	};

	static const struct luaL_reg node_meta_gc[] = {
		{ "__tostring", lbox_xmlnode_tostring	},
		{ "__gc",	lbox_xmlnode_gc		},
		{ NULL, NULL }
	};

	static const struct luaL_reg node_meta_nogc[] = {
		{ "__tostring", lbox_xmlnode_tostring	},
		{ NULL, NULL }
	};

	/* box.xml.lib_gc */
	luaL_newmetatable(L, "box.xml.lib_gc");
	luaL_register(L, NULL, node_meta_gc);

	lua_pushstring(L, "__index");
	lua_newtable(L);
	luaL_register(L, NULL, node_methods);
	lua_rawset(L, -3);
	lua_pop(L, 1);

	/* box.xml.lib_nogc */
	luaL_newmetatable(L, "box.xml.lib_nogc");
	luaL_register(L, NULL, node_meta_nogc);

	lua_pushstring(L, "__index");
	lua_newtable(L);
	luaL_register(L, NULL, node_methods);
	lua_rawset(L, -3);
	lua_pop(L, 1);

	return 0;
}

#else

static int
lbox_xml_notinstalled(struct lua_State *L)
{
	return luaL_error(L, "tarantool was not compiled with libxml2");
}

int
tarantool_lua_xml_init(struct lua_State *L)
{
	lua_getfield(L, LUA_GLOBALSINDEX, "box");

	lua_pushstring(L, "xml");
	lua_newtable(L);

	lua_pushstring(L, "enabled");
	lua_pushboolean(L, 0);
	lua_rawset(L, -3);

	lua_newtable(L);
	lua_pushstring(L, "__index");
	lua_pushcfunction(L, lbox_xml_notinstalled);
	lua_rawset(L, -3);
	lua_setmetatable(L, -2);

	lua_settable(L, -3);

	lua_pop(L, 1);
	return 0;
}

#endif /* ENABLE_LIBXML */
