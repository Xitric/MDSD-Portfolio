package org.iot.devicefactory.tests.scoping

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.CommonPackage
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.tests.MultiLanguageInjectorProvider
import org.iot.devicefactory.tests.TestUtil
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static extension org.iot.devicefactory.tests.TestUtil.*

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class DeviceFactoryScopingTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ScopingTestUtil
	@Inject extension TestUtil
	
	@Test def void testSensorScopeAvailable() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).devices.get(0).sensors.get(0).assertScope(
			Literals.SENSOR__DEFINITION,
			#["barometer"]
		)
	}
	
	@Test def void testSensorScopeHierarchy() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure_v2
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).devices.get(0).sensors.get(0).assertScope(
			Literals.SENSOR__DEFINITION,
			#["barometer", "thermistor"]
		)
	}
	
	@Test def void testSensorScopeChildDevice() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure_v2
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		
		device sub_controller includes controller
			override sensor barometer sample frequency 10
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).devices.get(1).sensors.get(0).assertScope(
			Literals.SENSOR__DEFINITION,
			#["barometer", "thermistor"]
		)
	}
	
	@Test def void testSensorScopeUnavailable() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).devices.get(0).sensors.get(0).assertScope(
			Literals.SENSOR__DEFINITION,
			#[]
		)
	}
	
	@Test def void testOutVariableScopeBaseDefinition() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		channel inserial
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint filter[true]
					out inserial filter[true]
		'''.parse(resourceSet).devices.get(0).sensors => [
			get(0).datas.get(0).outputs.get(0).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["b"]
			)
			get(0).datas.get(0).outputs.get(1).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["b"]
			)
		]
	}
	
	@Test def void testOutVariableScopeChildDefinition() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		channel inserial
		device controller board esp32_azure_v2
			sensor barometer sample signal
				data raw_pressure
					out endpoint filter[true]
					out inserial filter[true]
			sensor thermistor sample frequency 1
				data raw_temperature
					out inserial filter[true]
					out endpoint filter[true]
		'''.parse(resourceSet).devices.get(0).sensors => [
			get(0).datas.get(0).outputs.get(0).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
			get(0).datas.get(0).outputs.get(1).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
			get(1).datas.get(0).outputs.get(0).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["b", "c"]
			)
			get(1).datas.get(0).outputs.get(1).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["b", "c"]
			)
		]
	}
	
	@Test def void testOutVariableScopeLocal() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		channel inserial
		device controller board esp32_azure
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[p + 1 => q].filter[true]
					out inserial filter[true]
		'''.parse(resourceSet).devices.get(0).sensors.get(0).datas.get(0).outputs => [
			get(0).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
			get(0).pipeline.get(1).assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["q"]
			)
			get(1).pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
		]
	}
	
	@Test def void testOutVariableScopeChildDevice() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		channel inserial
		device controller board esp32_azure
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[p + 1 => q]
		device sub_controller includes controller
			override sensor barometer sample frequency 10
				data raw_pressure
					out endpoint filter[true]
		'''.parse(resourceSet).devices.get(1).sensors.get(0).datas.get(0).outputs.get(0).pipeline.assertScope(
			CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
		)
	}
}