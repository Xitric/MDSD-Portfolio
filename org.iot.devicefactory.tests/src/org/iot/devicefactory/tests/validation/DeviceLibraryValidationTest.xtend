package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.iot.devicefactory.common.CommonPackage
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.iot.devicefactory.validation.CommonIssueCodes
import org.iot.devicefactory.validation.DeviceLibraryIssueCodes
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class DeviceLibraryValidationTest {
	
	@Inject extension ParseHelper<Library>
	@Inject extension ValidationTestHelper
	@Inject Provider<ResourceSet> resourceSetProvider
	
	@Test def void testIllegalPackageStatement() {
		'''
		package iot.boards
		define board BoardA
			sensor a pin(12) as p
		'''.parse(URI.createURI("resource/DeviceFactory/src/base_boards.iotc"), resourceSetProvider.get)
			.assertError(
				Literals.LIBRARY,
				DeviceLibraryIssueCodes.ILLEGAL_PACKAGE,
				"There cannot be a package declaration in library files located outside a package"
			)
	}
	
	@Test def void testMissingPackageStatement() {
		'''
		define board BoardA
			sensor a pin(12) as p
		'''.parse(URI.createURI("resource/DeviceFactory/src/iot/base_boards.iotc"), resourceSetProvider.get)
			.assertError(
				Literals.LIBRARY,
				DeviceLibraryIssueCodes.INCORRECT_PACKAGE,
				"Incorrect package name, expected iot"
			)
	}
	
	@Test def void testIncorrectPackageStatement() {
		'''
		package ioot
		define board BoardA
			sensor a pin(12) as p
		'''.parse(URI.createURI("resource/DeviceFactory/src/iot/base_boards.iotc"), resourceSetProvider.get)
			.assertError(
				Literals.LIBRARY,
				DeviceLibraryIssueCodes.INCORRECT_PACKAGE,
				"Incorrect package name, expected iot"
			)
	}
	
	@Test def void testCorrectPackageStatement() {
		'''
		package iot
		define board BoardA
			sensor a pin(12) as p
		'''.parse(URI.createURI("resource/DeviceFactory/src/iot/base_boards.iotc"), resourceSetProvider.get)
			.assertNoErrors
	}
	
	@Test def void testIncorrectFileLocation() {
		'''
		package iot
		define board BoardA
			sensor a pin(12) as p
		'''.parse(URI.createURI("iot/base_boards.iotc"), resourceSetProvider.get)
			.assertError(
				Literals.LIBRARY,
				null,
				"A board library must be located inside the src folder of an Eclipse project"
			)
	}

	@Test def void testDuplicateBoards() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardA
			sensor b pin(12) as p
		'''.parse.assertError(
			Literals.BOARD,
			null,
			"Duplicate board names are not allowed. Choose a unique name"
		)
	}
	
	@Test def void testDuplicateBaseSensors() {
		'''
		define board BoardA
			sensor a pin(12) as p
			sensor a pin(12) as p
		'''.parse.assertDuplicateSensors("a")
	}
	
	@Test def void testDuplicateMixSensors() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor a pin(12) as p
			override sensor a
				preprocess filter[true]
		'''.parse.assertDuplicateSensors("a")
	}
	
	@Test def void testDuplicateOverrideSensors() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			override sensor a
				preprocess filter[true]
			override sensor a
				preprocess filter[true]
		'''.parse.assertDuplicateSensors("a")
	}
	
	@Test def void testDuplicateSensorsQualifiedNames() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB
			sensor a pin(12) as p
		
		define board BoardC includes BoardA, BoardB
			override sensor a
				preprocess filter[true]
			override sensor BoardA.a
				preprocess filter[true]
			override sensor BoardB.a
				preprocess filter[true]
		'''.parse.assertDuplicateSensors("a")
	}
	
	@Test def void testDuplicateSensorsDifferentReferences() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b pin(12) as p
		
		define board BoardC includes BoardA
			sensor c pin(12) as p
		
		define board BoardD includes BoardB, BoardC
			override sensor BoardB.a
				preprocess filter[true]
			override sensor BoardC.a
				preprocess filter[true]
		'''.parse.assertDuplicateSensors("a")
	}
	
	private def assertDuplicateSensors(Library library, String sensorName) {
		library.assertError(
			Literals.SENSOR_DEFINITION,
			DeviceLibraryIssueCodes.DUPLICATE_SENSOR,
			'''Duplicate sensor definition «sensorName» in same board'''
		)
	}
	
	@Test def void testMissingOverride() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor a pin(12) as p
		'''.parse.assertError(
			Literals.SENSOR_DEFINITION,
			DeviceLibraryIssueCodes.NON_OVERRIDING_SENSOR,
			"Redeclared sensor a must override inherited definition from parent"
		)
	}
	
	@Test def void testMissingOverrideInheritanceConflict() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB
			sensor a pin(12) as p
		
		define board BoardC includes BoardB, BoardA
			sensor a pin(12) as p
		'''.parse.assertError(
			Literals.SENSOR_DEFINITION,
			DeviceLibraryIssueCodes.NON_OVERRIDING_SENSOR,
			"Redeclared sensor a must override inherited definition from parent"
		)
	}
	
	@Test def void testMissingOverrideMultiInheritance() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b pin(12) as p
		
		define board BoardC
			sensor b pin(12) as p
		
		define board BoardD includes BoardC, BoardB
			sensor a pin(12) as p
		'''.parse.assertError(
			Literals.SENSOR_DEFINITION,
			DeviceLibraryIssueCodes.NON_OVERRIDING_SENSOR,
			"Redeclared sensor a must override inherited definition from parent"
		)
	}
	
	@Test def void testInvalidOverride() {
		'''
		define board BoardA
			override sensor a
		'''.parse.assertError(
			Literals.SENSOR_DEFINITION,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to SensorDefinition 'a'"
		)
	}
	
	@Test def void testInvalidOverrideWithParent() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			override sensor b
		'''.parse.assertError(
			Literals.SENSOR_DEFINITION,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to SensorDefinition 'b'."
		)
	}
	
	@Test def void testRequiredOverride() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b pin(12) as p
		
		define board BoardC
			sensor a pin(12) as p
		
		define board BoardD includes BoardB, BoardC
			sensor d pin(12) as p
		'''.parse.assertError(
			Literals.BOARD,
			DeviceLibraryIssueCodes.INHERITANCE_CONFLICT,
			"Sensor with identifier a refers to multiple inherited definitions. Resolve this ambiguity by explicitly overriding one of them"
		)
	}
	
	@Test def void testNoRequiredOverrideDiamond() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor b pin(12) as p
		
		define board BoardC includes BoardA
			sensor c pin(12) as p
		
		define board BoardD includes BoardB, BoardC
			sensor d pin(12) as p
		'''.parse.assertNoError(DeviceLibraryIssueCodes.INHERITANCE_CONFLICT)
	}
	
	@Test def void testDuplicateVariables() {
		'''
		define board BoardA
			sensor a pin(12, 13, 14) as (a, b, a)
		'''.parse.assertError(
			CommonPackage.Literals.VARIABLE_DECLARATION,
			null,
			"The variable a is a duplicate. All variable names in a tuple must be unique"
		)
	}
	
	@Test def void testPinVariables() {
		'''
		define board BoardA
			sensor a pin(12) as a
		'''.parse.assertNoError(DeviceLibraryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
		
		'''
		define board BoardA
			sensor a pin(12) as (a, b)
		'''.parse.assertError(
			Literals.BASE_SENSOR_DEFINITION,
			DeviceLibraryIssueCodes.INCORRECT_VARIABLE_DECLARATION,
			"Expected variable declaration to contain 1 variable, got 2"
		)
		
		'''
		define board BoardA
			sensor a pin(12, 13) as a
		'''.parse.assertError(
			Literals.BASE_SENSOR_DEFINITION,
			DeviceLibraryIssueCodes.INCORRECT_VARIABLE_DECLARATION,
			"Expected variable declaration to contain 2 variables, got 1"
		)
		
		'''
		define board BoardA
			sensor a pin(12, 13) as (a, b)
		'''.parse.assertNoError(DeviceLibraryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
	}
	
	@Test def void testI2cVariables() {
		'''
		define board BoardA
			sensor a i2c(0x5f) as a
		'''.parse.assertNoError(DeviceLibraryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
		
		'''
		define board BoardA
			sensor a i2c(0x5f) as (a, b)
		'''.parse.assertNoError(DeviceLibraryIssueCodes.INCORRECT_VARIABLE_DECLARATION)
	}
	
	@Test def void testWindowPipelineRoot() {
		'''
		define board BoardA
			sensor a pin(12) as a
				preprocess window[10].mean
		'''.parse.assertNoError(CommonIssueCodes.ILLEGAL_WINDOW_INPUT)
		
		'''
		define board BoardA
			sensor a pin(12, 13, 14) as (a, b, c)
				preprocess window[10].mean
		'''.parse.assertNoError(CommonIssueCodes.ILLEGAL_WINDOW_INPUT)
	}
	
	@Test def void testWindowPipelineAfterFilter() {
		'''
		define board BoardA
			sensor a pin(12, 13, 14) as (a, b, c)
				preprocess filter[true].window[10].mean
		'''.parse.assertNoError(CommonIssueCodes.ILLEGAL_WINDOW_INPUT)
	}
	
	@Test def void testWindowPipelineAfterWindow() {
		'''
		define board BoardA
			sensor a pin(12, 13, 14) as (a, b, c)
				preprocess window[10].max.window[10].mean
		'''.parse.assertNoError(CommonIssueCodes.ILLEGAL_WINDOW_INPUT)
	}
	
	@Test def void testWindowPipelineNonNumber() {
		'''
		define board BoardA
			sensor a pin(12) as p
				preprocess filter[true].window[10].mean.map[p > 0 => q]
		define board BoardB includes BoardA
			override sensor a
				preprocess window[10].mean
		'''.parse.assertError(
			CommonPackage.Literals.WINDOW,
			CommonIssueCodes.ILLEGAL_WINDOW_INPUT,
			"Window operations are only applicable on integer or double types, but is called on boolean"
		)
	}
}
