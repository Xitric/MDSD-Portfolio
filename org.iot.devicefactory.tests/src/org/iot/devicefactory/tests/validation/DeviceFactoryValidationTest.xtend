package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.tests.MultiLanguageInjectorProvider
import org.iot.devicefactory.tests.TestUtil
import org.iot.devicefactory.validation.DeviceFactoryValidator
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject extension TestUtil
	
	@Test def void testDeploymentNoChannel() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.MISSING_CHANNEL,
			"There must be at least one channel"
		)
	}
	
	@Test def void testDeploymentNoDevice() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.MISSING_DEVICE,
			"There must be at least one device"
		)
	}
	
	@Test def void testDeploymentMultipleFogs() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		fog
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		fog
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.AMBIGUOUS_FOG,
			"There can be at most one fog"
		)
	}
	
	@Test def void testDeploymentNoCloud() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.MISSING_CLOUD,
			"There must be a cloud"
		)
	}
	
	@Test def void testDeploymentMultipleClouds() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		cloud
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		cloud
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		'''.parse(resourceSet).assertError(
			Literals.DEPLOYMENT,
			DeviceFactoryValidator.AMBIGUOUS_CLOUD,
			"There can be at most one cloud"
		)
	}
	
	@Test def void testIllegalBoardReference() {
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse.assertError(
			Literals.BASE_DEVICE,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Board 'esp32'"
		)
	}
	
	@Test def void testFullyQualifiedBoard() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board iot.boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testImportedBoard() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.esp32
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testWildcardImport() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testPackageImport() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.*
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testPackageImportNoWildcard() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.BASE_DEVICE,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Board 'boards.esp32'"
		)
	}
	
	@Test def void testUnknownImport() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library ioot
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.LIBRARY,
			DeviceFactoryValidator.SUPERFLUOUS_LIBRARY,
			"No resource found with qualified name ioot"
		)
	}
	
	@Test def void testSuperfluousImport() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		library esp32
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertWarning(
			Literals.LIBRARY,
			DeviceFactoryValidator.SUPERFLUOUS_LIBRARY,
			"Unnecessary import of library esp32 has no effect"
		)
	}
	
	@Test def void testLegalLanguage() {
		'''
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse.assertNoError(DeviceFactoryValidator.UNSUPPORTED_LANGUAGE)
	}
	
	@Test def void testIllegalLanguage() {
		'''
		language brainfuck
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse.assertError(
			Literals.LANGUAGE,
			DeviceFactoryValidator.UNSUPPORTED_LANGUAGE,
			"Unsupported language brainfuck"
		)
	}
	
	@Test def void testLegalDeployment() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		device mega_controller includes controller
			override sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		fog
			transformation raw_pressure as t
				data scaled_pressure
					out filter[true]
		cloud
			transformation scaled_pressure as t
				data new_pressure
					out filter[true]
		'''.parse(resourceSet).assertNoErrors
	}
	
	@Test def void testLegalOuts() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b * b => a]
					out endpoint map[b + b => b]
					out endpoint map[2 => c]
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.INCORRECT_OUT_TYPE)
	}
	
	@Test def void testOutsNumberTypes() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[2.4 => a]
					out endpoint map[2 => a]
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.INCORRECT_OUT_TYPE)
	}
	
	@Test def void testOutsNoPipelines() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint
					out endpoint
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.INCORRECT_OUT_TYPE)
	}
	
	@Test def void testOutsDifferentTypes() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b * b => a]
					out endpoint map[b > 5 => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryValidator.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected integer, got boolean"
		)
	}
	
	@Test def void testOutsChildDevice() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b > 5 => a]
		device controller_child includes controller
			override sensor barometer
				data raw_pressure
					out endpoint map[true => a]
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.INCORRECT_OUT_TYPE)
	}
	
	@Test def void testOutsChildDeviceDifferentTypes() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b > 5 => a]
		device controller_child includes controller
			override sensor barometer
				data raw_pressure
					out endpoint map[b => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryValidator.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected boolean, got integer"
		)
	}
	
	@Test def void testOutsDeepChildDeviceDifferentTypes() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b > 5 => a]
		device controller_child includes controller
			override sensor barometer
				data raw_pressure
					out endpoint map[b => a]
		device controller_grandchild includes controller_child
			override sensor barometer
				data raw_pressure
					out endpoint map[3e8 => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryValidator.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected boolean, got integer"
		)
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b > 5 => a]
		device controller_child includes controller
			override sensor barometer
				data raw_pressure
					out endpoint map[b => a]
		device controller_grandchild includes controller_child
			override sensor barometer
				data raw_pressure
					out endpoint map[3e8 => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryValidator.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected boolean, got double"
		)
	}
	
	@Test def void testOutsDefinedInChildDevice() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32
			in inserial
			sensor motion sample signal
				data raw_pressure
					out endpoint
		device controller_child includes controller
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b > 5 => a]
		device controller_grandchild includes controller_child
			override sensor barometer
				data raw_pressure
					out endpoint map[b => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryValidator.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected boolean, got integer"
		)
	}
	
	@Test def void testOutTypesNoPipeline() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controller board esp32_azure_v2
			in inserial
			sensor thermistor sample signal
				data raw_temperature
					out endpoint
		device controller_child includes controller
			override sensor thermistor
				data raw_temperature
					out endpoint map[5 => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryValidator.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected (integer, integer), got integer"
		)
	}
}
