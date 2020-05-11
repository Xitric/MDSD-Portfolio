package org.iot.devicefactory.tests

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.util.StringInputStream

class TestUtil {

	@Inject Provider<ResourceSet> resourceSetProvider

	def makeRootBoardLibrary() {
		makeBoardLibrary("")
	}

	def makePackagedBoardLibrary() {
		makeBoardLibrary("iot.boards")
	}

	def makeBoardLibrary(String pkg) {
		val resourceSet = resourceSetProvider.get
		val resourceURI = '''resource/DeviceFactory/src/«pkg.replace(".", "/") + "/"»base_boards.iotc'''

		val iotc = resourceSet.createResource(URI.createURI(resourceURI))
		iotc.load(new StringInputStream('''
			«IF !pkg.empty»package «pkg»«ENDIF»
			define board esp32
				sensor barometer i2c(0x6D) as b
			
			define board esp32_azure includes esp32
				override sensor barometer
					preprocess map[b => p]
			
			define board esp32_azure_v2 includes esp32_azure
				sensor thermistor pin(12) as a
					preprocess map[a * a => (b, c)]
		'''), emptyMap)
		return resourceSet
	}
}
