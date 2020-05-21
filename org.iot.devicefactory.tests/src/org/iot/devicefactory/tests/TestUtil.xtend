package org.iot.devicefactory.tests

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.util.StringInputStream
import org.iot.devicefactory.common.Pipeline

class TestUtil {

	@Inject Provider<ResourceSet> resourceSetProvider

	def makeRootBoardLibrary() {
		makeSimpleBoardLibrary("")
	}

	def makePackagedBoardLibrary() {
		makeSimpleBoardLibrary("iot.boards")
	}

	private def makeSimpleBoardLibrary(String pkg) {
		makeBoardLibrary(pkg,
		'''
		define board esp32
			sensor barometer i2c(0x6D) as b
		
		define board esp32_azure includes esp32
			override sensor barometer
				preprocess map[b => p]
		
		define board esp32_azure_v2 includes esp32_azure
			sensor thermistor pin(12) as a
				preprocess map[(a * a, a) => (b, c)]
		''')
	}
	
	def makeInheritanceBoardLibrary() {
		makeBoardLibrary("",
		'''
		define board BoardA
			sensor a i2c(0x6D) as b
		
		define board BoardB includes BoardA
			sensor b pin(12) as p
		
		define board BoardC
			sensor a pin(12) as a
		
		define board BoardD includes BoardB, BoardC
			override sensor BoardB.a
		
		define board BoardE includes BoardA
			sensor e pin(12) as p
		
		define board BoardF includes BoardB, BoardE
			sensor f pin(12) as p
		
		define board BoardG includes BoardF, BoardC
			override sensor BoardC.a
		''')
	}

	private def makeBoardLibrary(String pkg, CharSequence content) {
		val resourceSet = resourceSetProvider.get
		val resourceURI = '''resource/DeviceFactory/src/«pkg.replace(".", "/") + "/"»base_boards.iotc'''

		val iotc = resourceSet.createResource(URI.createURI(resourceURI))
		iotc.load(new StringInputStream('''
			«IF !pkg.empty»package «pkg»«ENDIF»
			«content»
		'''), emptyMap)
		return resourceSet
	}
	
	static def get(Pipeline pipeline, int index) {
		var current = pipeline
		for (var i = 0; i < index; i++) {
			current = current.next
		}
		return current
	}
}
