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
import org.iot.devicefactory.validation.DeviceFactoryValidator
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryDuplicationValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject extension TestUtil
	
	@Test def void testDuplicateChannels() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.CHANNEL,
			DeviceFactoryValidator.DUPLICATE_CHANNEL,
			"Duplicate channel endpoint"
		)
	}
	
	@Test def void testNoDuplicateChannels() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.DUPLICATE_CHANNEL)
	}
	
	@Test def void testDuplicateDevices() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller board esp32_azure
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.DEVICE,
			DeviceFactoryValidator.DUPLICATE_DEVICE,
			"Duplicate device controller"
		)
	}
	
	@Test def void testDuplicateDevicesOverride() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller includes controller
			override sensor barometer
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.DEVICE,
			DeviceFactoryValidator.DUPLICATE_DEVICE,
			"Duplicate device controller"
		)
	}
	
	@Test def void testNoDuplicateDevices() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.DUPLICATE_DEVICE)
	}
	
	@Test def void testDuplicateBaseSensors() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertDuplicateSensors("barometer")
	}
	
	@Test def void testDuplicateMixSensors() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			sensor barometer sample signal
				data raw_pressure
					out endpoint
			override sensor barometer
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertDuplicateSensors("barometer")
	}
	
	@Test def void testDuplicateOverrideSensors() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		device controller_child includes controller
			override sensor barometer
				data raw_pressure
					out endpoint
			override sensor barometer
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertDuplicateSensors("barometer")
	}
	
	@Test def void testNoDuplicateSensors() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.DUPLICATE_SENSOR)
	}
	
	private def assertDuplicateSensors(Deployment deployment, String sensorName) {
		deployment.assertError(
			Literals.SENSOR,
			DeviceFactoryValidator.DUPLICATE_SENSOR,
			'''Duplicate sensor definition «sensorName» in same device'''
		)
	}
	
	@Test def void testDuplicateDatas() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.DATA,
			DeviceFactoryValidator.DUPLICATE_DATA,
			"Duplicate data raw_pressure in same sensor"
		)
	}
	
	@Test def void testNoDuplicateDatas() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(DeviceFactoryValidator.DUPLICATE_DATA)
	}
}
