package org.iot.devicefactory.tests.typing

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.tests.MultiLanguageInjectorProvider
import org.iot.devicefactory.tests.TestUtil
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.iot.devicefactory.tests.TestUtil.*
import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(MultiLanguageInjectorProvider)
class ReferenceTypeFactoryTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ExpressionTypeChecker
	@Inject extension TestUtil
	
	@Test def void testReferenceUndefined() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint filter[a]
		'''.parse(resourceSet).devices.get(0).sensors.get(0).datas.get(0).outputs.get(0).pipeline => [
			(get(0) as Filter).expression.typeOf.assertSame(VOID)
		]
	}
	
	@Test def void testReferenceDefined() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint filter[b]
		'''.parse(resourceSet).devices.get(0).sensors.get(0).datas.get(0).outputs.get(0).pipeline => [
			(get(0) as Filter).expression.typeOf.assertSame(INTEGER)
		]
	}
	
	@Test def void testReferenceBoardOverridden() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure
			sensor barometer sample signal
				data raw_pressure
					out endpoint filter[b].filter[p]
		'''.parse(resourceSet).devices.get(0).sensors.get(0).datas.get(0).outputs.get(0).pipeline => [
			(get(0) as Filter).expression.typeOf.assertSame(VOID)
			(get(1) as Filter).expression.typeOf.assertSame(INTEGER)
		]
	}
	
	@Test def void testReferenceBasePreprocess() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32_azure_v2
			sensor thermistor sample signal
				data raw_temperature
					out endpoint filter[a].filter[b].filter[c]
		'''.parse(resourceSet).devices.get(0).sensors.get(0).datas.get(0).outputs.get(0).pipeline => [
			(get(0) as Filter).expression.typeOf.assertSame(VOID)
			(get(1) as Filter).expression.typeOf.assertSame(INTEGER)
			(get(2) as Filter).expression.typeOf.assertSame(INTEGER)
		]
	}
	
	@Test def void testReferenceChildDevice() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint map[b => q]
		device controller_child includes controller
			sensor barometer
				data raw_pressure
					out endpoint filter[q].filter[b]
		'''.parse(resourceSet).devices.get(1).sensors.get(0).datas.get(0).outputs.get(0).pipeline => [
			(get(0) as Filter).expression.typeOf.assertSame(VOID)
			(get(1) as Filter).expression.typeOf.assertSame(INTEGER)
		]
	}
}
