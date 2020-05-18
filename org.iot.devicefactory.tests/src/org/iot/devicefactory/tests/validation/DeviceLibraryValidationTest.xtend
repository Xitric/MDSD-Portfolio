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
	
	private def assertDuplicateSensors(Library library, String sensorName) {
		library.assertError(
			Literals.SENSOR,
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
			Literals.SENSOR,
			DeviceLibraryIssueCodes.NON_OVERRIDING_SENSOR,
			"Redeclared sensor a must override inherited definition from parent"
		)
	}
	
	@Test def void testInvalidOverride() {
		'''
		define board BoardA
			override sensor a
		'''.parse.assertError(
			Literals.SENSOR,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Sensor 'a'"
		)
	}
	
	@Test def void testInvalidOverrideWithParent() {
		'''
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			override sensor b
		'''.parse.assertError(
			Literals.SENSOR,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Sensor 'b'."
		)
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
