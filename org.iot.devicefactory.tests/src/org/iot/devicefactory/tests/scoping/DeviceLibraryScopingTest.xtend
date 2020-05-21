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
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class DeviceLibraryScopingTest {
	
	@Inject extension ParseHelper<Library>
	@Inject extension ScopingTestUtil
	
	@Test def void boardScope_NoForwardReferences() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB
			sensor b pin(12) as p
		
		define board BoardC
			sensor c pin(12) as p
		'''.parse.boards => [
			get(0).assertScope(
				Literals.BOARD__PARENTS,
				#[]
			)
			get(1).assertScope(
				Literals.BOARD__PARENTS,
				#["BoardA"]
			)
			get(2).assertScope(
				Literals.BOARD__PARENTS,
				#["BoardA", "BoardB"]
			)
		]
	}
	
	@Test def void sensorScope_SingleInheritance() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB
			sensor b pin(12) as p
			sensor c i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardB
			override sensor b
		'''.parse.boards => [
			get(1).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#[]
			)
			get(1).sensors.get(1).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#[]
			)
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["b", "c", "BoardB.b", "BoardB.c"]
			)
		]
	}
	
	@Test def void sensorScope_ChainedInheritance() {
		'''
		define board BoardA
			sensor a pin(12) as p
			sensor b pin(12) as p
		
		define board BoardB includes BoardA
			override sensor a
			sensor c i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardB
			override sensor c
		'''.parse.boards => [
			get(1).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "b", "BoardA.a", "BoardA.b"]
			)
			get(1).sensors.get(1).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "b", "BoardA.a", "BoardA.b"]
			)
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "b", "c", "BoardB.a", "BoardB.b", "BoardB.c"]
			)
		]
	}
	
	@Test def void sensorScope_MultipleInheritance() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardA, BoardB
			override sensor b
		'''.parse.boards => [
			get(0).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#[]
			)
			get(1).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#[]
			)
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "b", "BoardA.a", "BoardB.b"]
			)
		]
	}
	
	@Test def void sensorScope_MultipleInheritanceUnambiguousDuplicate() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardA, BoardB
			override sensor b
		
		define board BoardD includes BoardB, BoardA
			override sensor b
		'''.parse.boards => [
			get(0).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#[]
			)
			get(1).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "BoardA.a"]
			)
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "b", "BoardA.a", "BoardB.a", "BoardB.b"]
			)
			get(3).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "b", "BoardA.a", "BoardB.a", "BoardB.b"]
			)
		]
	}
	
	@Test def void sensorScope_MultipleInheritanceDiamond() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardA
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardD includes BoardB, BoardC
			override sensor b
		'''.parse.boards => [
			get(0).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#[]
			)
			get(1).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "BoardA.a"]
			)
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "BoardA.a"]
			)
			get(3).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "BoardB.a", "BoardB.b", "BoardC.a", "BoardC.b"]
			)
		]
	}
	
	@Test def void sensorScope_MultipleInheritanceConflicts() {
		'''
		define board BoardA
			sensor a pin(12) as p
			sensor b pin(12) as p
		
		define board BoardB includes BoardA
			sensor b i2c(0x5f) as (x, y, z)
			sensor c i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardA, BoardB
			override sensor a
		'''.parse.boards => [
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "c", "BoardA.a", "BoardA.b", "BoardB.a", "BoardB.b", "BoardB.c"]
			)
		]
	}
	
	@Test def void sensorScope_MultipleInheritanceConflictsSeparateParents() {
		'''
		define board BoardA
			sensor a pin(12) as p
			sensor b pin(12) as p
		
		define board BoardB
			sensor b i2c(0x5f) as (x, y, z)
			sensor c i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardA, BoardB
			override sensor a
		'''.parse.boards => [
			get(2).sensors.get(0).assertScope(
				Literals.OVERRIDE_SENSOR_DEFINITION__PARENT,
				#["a", "c", "BoardA.a", "BoardA.b", "BoardB.b", "BoardB.c"]
			)
		]
	}
	
	@Test def void sensorScope_ReferencesDiamond() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardA
			sensor c i2c(0x5f) as (x, y, z)
		
		define board BoardD includes BoardB, BoardC
			override sensor a
				preprocess filter[true]
			override sensor BoardB.a
				preprocess filter[true]
			override sensor BoardC.a
				preprocess filter[true]
			override sensor b
				preprocess filter[true]
			override sensor c
				preprocess filter[true]
		'''.parse.boards => [
			(get(3).sensors.get(0) as OverrideSensorDefinition).parent.assertSame(
				get(0).sensors.get(0)
			)
			(get(3).sensors.get(1) as OverrideSensorDefinition).parent.assertSame(
				get(0).sensors.get(0)
			)
			(get(3).sensors.get(2) as OverrideSensorDefinition).parent.assertSame(
				get(0).sensors.get(0)
			)
			(get(3).sensors.get(3) as OverrideSensorDefinition).parent.assertSame(
				get(1).sensors.get(0)
			)
			(get(3).sensors.get(4) as OverrideSensorDefinition).parent.assertSame(
				get(2).sensors.get(0)
			)
		]
	}
	
	@Test def void sensorScope_ReferencesShadowed() {
		'''
		define board BoardA
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardB
			sensor a pin(12) as p
			sensor b i2c(0x5f) as (x, y, z)
		
		define board BoardC includes BoardB
			override sensor a
				filter[true]
		
		define board BoardC includes BoardA, BoardC
			override sensor BoardA.b
				preprocess filter[true]
			override sensor BoardC.b
				preprocess filter[true]
			override sensor a
				preprocess filter[true]
			override sensor BoardC.a
				preprocess filter[true]
		'''.parse.boards => [
			(get(3).sensors.get(0) as OverrideSensorDefinition).parent.assertSame(
				get(0).sensors.get(0)
			)
			(get(3).sensors.get(1) as OverrideSensorDefinition).parent.assertSame(
				get(1).sensors.get(1)
			)
			(get(3).sensors.get(2) as OverrideSensorDefinition).parent.assertSame(
				get(2).sensors.get(0)
			)
			(get(3).sensors.get(3) as OverrideSensorDefinition).parent.assertSame(
				get(2).sensors.get(0)
			)
		]
	}
	
	@Test def void variableScope_BaseSensorDefinition() {
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
	
	@Test def void variableScope_ParentSensor() {
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
	
	@Test def void variableScope_Shadowing() {
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
	
	@Test def void variableScope_ParentPreprocess() {
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
	
	@Test def void variableScope_NoPreprocess() {
		'''
		define board BoardA
			sensor a pin(12, 13, 14) as (p, q, r)
				preprocess filter[true]
		
		define board BoardB
			sensor a pin(12, 13, 14) as (h, i, j)
				preprocess filter[true]
		
		define board BoardC includes BoardA, BoardB
			override sensor BoardA.a
		
		define board BoardD includes BoardC
			override sensor a
				preprocess filter[true]
		
		define board BoardE includes BoardA, BoardB
			override sensor BoardB.a
		
		define board BoardF includes BoardE
			override sensor a
				preprocess filter[true]
		'''.parse.boards => [
			get(3).sensors.get(0).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["p", "q", "r"]
			)
			get(5).sensors.get(0).preprocess.pipeline.assertScope(
				CommonPackage.Literals.REFERENCE__VARIABLE,
				#["h", "i", "j"]
			)
		]
	}
	
	@Test def void variableScope_References() {
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
