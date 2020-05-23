package org.iot.devicefactory.generator.python

import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import java.util.Map
import java.util.Set
import org.iot.devicefactory.deviceFactory.Channel

class GeneratorEnvironment {

	Map<String, Set<String>> imports
	Set<Channel> channels
	Set<String> libFiles

	new() {
		this(emptySet)
	}
	
	new(Collection<String> libFiles) {
		this.imports = new HashMap()
		this.channels = new HashSet()
		this.libFiles = new HashSet(libFiles)
	}

	def String useImport(String module) {
		imports.putIfAbsent(module, new HashSet())
		return module
	}

	def String useImport(String module, String definition) {
		useImport(module)
		val definitions = imports.get(module)
		definitions.add(definition)
		imports.put(module, definitions)
		return definition
	}

	def Iterable<String> getModuleImports() {
		imports.filter[key, value|value.empty].keySet
	}

	def Iterable<String> getDefinitionImports() {
		imports.filter[key, value|!value.empty].keySet
	}

	def Iterable<String> getDefinitionsFor(String module) {
		return imports.get(module)
	}

	def Channel useChannel(Channel channel) {
		channels.add(channel)
		return channel
	}

	def Iterable<Channel> getChannels() {
		return channels
	}

	def useLibFile(String name) {
		libFiles.add(name)
	}

	def getLibFiles() {
		return libFiles
	}
}
