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
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

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
			Literals.BASE_SENSOR__DEFINITION,
			#["barometer", "esp32.barometer"]
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
			Literals.BASE_SENSOR__DEFINITION,
			#["barometer", "thermistor", "esp32_azure_v2.barometer", "esp32_azure_v2.thermistor"]
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
			Literals.BASE_SENSOR__DEFINITION,
			#["barometer", "thermistor", "esp32_azure_v2.barometer", "esp32_azure_v2.thermistor"]
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
			Literals.BASE_SENSOR__DEFINITION,
			#[]
		)
	}
	
	@Test def void testSensorScopeMultiInheritance() {
		val resourceSet = makeInheritanceBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controllerA board BoardD
			sensor a sample signal
				data raw_pressure
					out endpoint
		
		device controllerB board BoardF
			sensor a sample signal
				data raw_pressure
					out endpoint
		
		device controllerB board BoardG
			sensor a sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).devices => [
			get(0).sensors.get(0).assertScope(
				Literals.BASE_SENSOR__DEFINITION,
				#["a", "b", "BoardD.a", "BoardD.b"]
			)
			
			get(1).sensors.get(0).assertScope(
				Literals.BASE_SENSOR__DEFINITION,
				#["a", "b", "e", "f", "BoardF.a", "BoardF.b", "BoardF.e", "BoardF.f"]
			)
			
			get(2).sensors.get(0).assertScope(
				Literals.BASE_SENSOR__DEFINITION,
				#["a", "b", "e", "f", "BoardG.a", "BoardG.b", "BoardG.e", "BoardG.f"]
			)
		]
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
	
	@Test def void testDataScopeFogEmpty() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		fog
			transformation some_data as a
				data derived_data
					out filter[true]
		'''.parse(resourceSet).fog.transformations.get(0).assertScope(
			Literals.TRANSFORMATION__PROVIDER,
			#[]
		)
	}
	
	@Test def void testDataScopeFog() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[p + 1 => q]
		device sub_controller includes controller
			override sensor barometer sample frequency 10
				data some_data
					out endpoint filter[true]
		cloud
			transformation some_data as a
				data cloud_data
					out filter[true]
		fog
			transformation some_data as a
				data fog_data
					out filter[true]
		'''.parse(resourceSet).fog.transformations.get(0).assertScope(
			Literals.TRANSFORMATION__PROVIDER,
			#["raw_pressure", "some_data"]
		)
	}
	
	@Test def void testDataScopeCloud() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[p + 1 => q]
		device sub_controller includes controller
			override sensor barometer sample frequency 10
				data some_data
					out endpoint filter[true]
		cloud
			transformation some_data as a
				data cloud_data
					out filter[true]
		fog
			transformation some_data as a
				data fog_data
					out filter[true]
		'''.parse(resourceSet).cloud.transformations.get(0).assertScope(
			Literals.TRANSFORMATION__PROVIDER,
			#["raw_pressure", "some_data", "fog_data"]
		)
	}
}