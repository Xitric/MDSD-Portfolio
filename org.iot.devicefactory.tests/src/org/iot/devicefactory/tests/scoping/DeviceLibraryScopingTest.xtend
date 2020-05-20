package org.iot.devicefactory.tests.scoping

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.CommonPackage
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class DeviceLibraryScopingTest {
	
	@Inject extension ParseHelper<Library>
	@Inject extension ScopingTestUtil
	
	// No forward references for board parents
	@Test def void testBoardScope() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB
			sensor b pin(12) as p
		
		define board BoardC
			sensor c pin(12) as p
		'''.parse.boards => [
			get(0).assertScope(
				Literals.BOARD__PARENT,
				#[]
			)
			get(1).assertScope(
				Literals.BOARD__PARENT,
				#["BoardA"]
			)
			get(2).assertScope(
				Literals.BOARD__PARENT,
				#["BoardA", "BoardB"]
			)
		]
	}
	
	// Pipeline scope using variable from base sensor
	@Test def void testBaseSensorVariableScope() {
		'''
		define board BoardA
			sensor a pin(12) as p
				preprocess filter[true]
			
			sensor b pin(12, 13, 14) as (p, q, r)
				preprocess filter[true]
		'''.parse.boards.get(0).sensors => [
			get(0).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
			get(1).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p", "q", "r"]
			)
		]
	}
	
	// Pipeline scope using variable from parent sensor
	@Test def void testParentSensorVariableScope() {
		'''
		define board BoardA
			sensor a pin(12) as p
			
			sensor b pin(12) as p
				preprocess filter[true]
			
			sensor c pin(12, 13, 14) as (p, q, r)
				preprocess filter[true]
		
		define board BoardB includes BoardA
			override sensor a
				preprocess filter[true]
			
			override sensor b
				preprocess filter[true]
			
			override sensor c
				preprocess filter[true]
		'''.parse.boards.get(1).sensors => [
			get(0).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
			get(1).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p"]
			)
			get(2).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p", "q", "r"]
			)
		]
	}
	
	// Pipeline scope using variables from immediate parent sensor
	@Test def void testParentSensorVariableScopeShadowing() {
		'''
		define board BoardA
			sensor a pin(12, 13, 14) as (p, q, r)
				preprocess filter[true]
		
		define board BoardB includes BoardA
			override sensor a
				preprocess map[q => k]
		
		define board BoardC includes BoardB
			override sensor a
				preprocess filter[true]
		'''.parse.boards.get(2).sensors => [
			get(0).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["k"]
			)
		]
	}
	
	// Pipeline scope using variable from parent preprocess only
	@Test def void testParentSensorPreprocessScope() {
		'''
		define board BoardA
			sensor a pin(12) as p
				preprocess map[p => k]
			
			sensor b pin(12) as p
				preprocess map[p => (k, l)]
			
			sensor c pin(12, 13) as (p, q)
				preprocess map[p + q => (k, l, m)]
		
		define board BoardB includes BoardA
			override sensor a
				preprocess filter[true]
			
			override sensor b
				preprocess filter[true]
			
			override sensor c
				preprocess filter[true]
		'''.parse.boards.get(1).sensors => [
			get(0).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["k"]
			)
			get(1).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
			get(2).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["k", "l", "m"]
			)
		]
	}
	
	@Test def void testParentSensorScopeReferences() {
		'''
		define board BoardA
			sensor a pin(12) as p
				preprocess map[p => p]
		
		define board BoardB includes BoardA
			override sensor a
				preprocess map[p => p]
		
		define board BoardC includes BoardB
			override sensor a
				preprocess map[p => p]
		'''.parse.boards => [
			((get(0).sensors.get(0).preprocess.pipeline as Map).expression as Reference).variable.assertSame(
				(get(0).sensors.get(0) as BaseSensorDefinition).input.variables
			)
			((get(1).sensors.get(0).preprocess.pipeline as Map).expression as Reference).variable.assertSame(
				(get(0).sensors.get(0).preprocess.pipeline as Map).output
			)
			((get(2).sensors.get(0).preprocess.pipeline as Map).expression as Reference).variable.assertSame(
				(get(1).sensors.get(0).preprocess.pipeline as Map).output
			)
		]
	}
}
