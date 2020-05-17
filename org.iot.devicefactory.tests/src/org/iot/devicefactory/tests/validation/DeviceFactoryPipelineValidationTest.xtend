package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.tests.MultiLanguageInjectorProvider
import org.iot.devicefactory.tests.TestUtil
import org.iot.devicefactory.validation.DeviceFactoryIssueCodes
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryPipelineValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject extension TestUtil
	
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
		'''.parse(resourceSet).assertNoError(DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE)
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
		'''.parse(resourceSet).assertNoError(DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE)
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
		'''.parse(resourceSet).assertNoError(DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE)
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
			DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
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
		'''.parse(resourceSet).assertNoError(DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE)
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
			DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
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
		'''.parse(resourceSet) => [
			assertError(
				Literals.SENSOR_DATA_OUT,
				DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
				"Incorrect output type from data pipeline. Expected boolean, got integer"
			)
			assertError(
				Literals.SENSOR_DATA_OUT,
				DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
				"Incorrect output type from data pipeline. Expected boolean, got double"
			)
		]
	}
	
	@Test def void testOutsDefinedInChildDevice() {
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
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b > 5 => a]
		device controller_grandchild includes controller_child
			override sensor barometer
				data raw_pressure
					out endpoint map[b => a]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
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
			DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected (integer, integer), got integer"
		)
	}
	
	@Test def void testOutTypesNoHierarchy() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controllerA board esp32
			in inserial
			sensor barometer sample signal
				data some_data
					out endpoint map[b > 5 => a]
		device controllerB board esp32_azure_v2
			in inserial
			sensor thermistor sample frequency 5
				data some_data
					out endpoint map[b > 5 && c < 0 => d]
		'''.parse(resourceSet).assertNoError(DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE)
	}
	
	@Test def void testOutsDifferentTypesNoHierarchy() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel inserial
		channel endpoint
		device controllerA board esp32
			in inserial
			sensor barometer sample signal
				data some_data
					out endpoint map[b > 5 => a]
		device controllerB board esp32_azure_v2
			in inserial
			sensor thermistor sample frequency 5
				data some_data
					out endpoint map[b => d]
		'''.parse(resourceSet).assertError(
			Literals.SENSOR_DATA_OUT,
			DeviceFactoryIssueCodes.INCORRECT_OUT_TYPE,
			"Incorrect output type from data pipeline. Expected boolean, got integer"
		)
	}
}
