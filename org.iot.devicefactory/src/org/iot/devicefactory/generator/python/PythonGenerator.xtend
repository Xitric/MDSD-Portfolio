package org.iot.devicefactory.generator.python

import org.iot.devicefactory.generator.LanguageGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

class PythonGenerator implements LanguageGenerator {
	
	override getLanguage() {
		"python"
	}
	
	override generate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		
	}
}