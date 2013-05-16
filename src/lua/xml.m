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
	lua_pushstring(L, "raw");
	lua_rawget(L, index);
	xmlNodePtr node = lua_touserdata(L, -1);
	lua_pop(L, 1);
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
lbox_xmlnode_add_child(struct lua_State *L)
{
	xmlNodePtr node = lua_toxmlnode(L, 1);
	xmlNodePtr child = lua_toxmlnode(L, 2);

	if (child->next || child->prev || child->parent)
		luaL_error(L, "child is already inserted in tree");

	if (xmlAddChild(node, child)) {

		/* inserted node needn't to be freed by lua gc */
		lua_getmetatable(L, 2);
		lua_pushstring(L, "__gc");
		lua_pushnil(L);
		lua_rawset(L, -3);
		lua_pop(L, 1);

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

	lua_getmetatable(L, 1);
	lua_pushstring(L, "__gc");
	lua_pushcfunction(L, lbox_xmlnode_gc);
	lua_rawset(L, -3);
	lua_pop(L, 1);

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
	static const struct luaL_reg node_methods[] = {
		{ "xpath",	lbox_xmlnode_xpath	},
		{ "attribute",	lbox_xmlnode_attribute	},
		{ "parent",	lbox_xmlnode_parent	},
		{ "add_child",	lbox_xmlnode_add_child	},
		{ "clone",	lbox_xmlnode_clone	},
		{ "remove",	lbox_xmlnode_remove	},
		{ "text",	lbox_xmlnode_text	},
		{ NULL, NULL }
	};
	static const struct luaL_reg node_meta[] = {
		{ "__tostring", lbox_xmlnode_tostring	},
		{ "__gc", lbox_xmlnode_gc		},
		{ NULL, NULL }
	};

	lua_newtable(L);
	lua_pushstring(L, "raw");
	lua_pushlightuserdata(L, node);
	lua_settable(L, -3);

	lua_newtable(L);
	luaL_register(L, NULL, node_meta);

	lua_pushstring(L, "__index");
	lua_newtable(L);
	luaL_register(L, NULL, node_methods);
	lua_rawset(L, -3);

	if (!was_alloc) {
		lua_pushstring(L, "__gc");
		lua_pushnil(L);
		lua_rawset(L, -3);
	}

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
