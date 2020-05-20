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
import org.iot.devicefactory.validation.DeviceFactoryIssueCodes
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryInheritanceValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject extension TestUtil
	
	@Test def void testIllegalSensorOverride() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure_v2
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			override sensor thermistor
				data raw_temperature
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.OVERRIDE_SENSOR,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Sensor 'thermistor'"
		)
	}
	
	@Test def void testBaseSensorOverride() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			override sensor barometer
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.OVERRIDE_SENSOR,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Sensor 'barometer'"
		)
	}
	
	@Test def void testMissingSensorOverride() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.BASE_SENSOR,
			DeviceFactoryIssueCodes.MISSING_OVERRIDE,
			"Redeclared sensor barometer must override inherited definition from parent"
		)
	}
	
	@Test def void testLegalSensorOverride() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure
			in endpoint
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			override sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet) => [
			assertNoError(DeviceFactoryIssueCodes.ILLEGAL_OVERRIDE)
			assertNoError(DeviceFactoryIssueCodes.MISSING_OVERRIDE)
		]
	}
	
	@Test def void testSignalSamplerInput() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32_azure
			in endpoint
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoErrors
	}
	
	@Test def void testSignalSamplerNoInput() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32_azure
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.BASE_SENSOR,
			DeviceFactoryIssueCodes.MISSING_INPUT_CHANNEL,
			"Cannot use signal sampling on a device with no input channel"
		)
	}
	
	@Test def void testSignalSamplerInheritedInput() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32_azure
			in endpoint
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			override sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoErrors
	}
	
	@Test def void testSignalSamplerNoInheritedInput() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32_azure
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			override sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.OVERRIDE_SENSOR,
			DeviceFactoryIssueCodes.MISSING_INPUT_CHANNEL,
			"Cannot use signal sampling on a device with no input channel"
		)
	}
}
