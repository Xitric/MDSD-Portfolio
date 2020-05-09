package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.iot.devicefactory.validation.DeviceLibraryValidator
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class DeviceLibraryValidationTest {
	
	@Inject extension ParseHelper<Library>
	@Inject extension ValidationTestHelper
	

	@Test def void testDuplicateBoards() {
		'''
		package iot
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
		package iot
		define board BoardA
			sensor a pin(12) as p
			sensor a pin(12) as p
		'''.parse.assertDuplicateSensors("a")
	}
	
	@Test def void testDuplicateMixSensors() {
		'''
		package iot
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor a pin(12) as p
			override sensor a
				preprocess filter[true
		'''.parse.assertDuplicateSensors("a")
	}
	
	@Test def void testDuplicateOverrideSensors() {
		'''
		package iot
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			override sensor a
				preprocess filter[true]
			override sensor a
				preprocess filter[true
		'''.parse.assertDuplicateSensors("a")
	}
	
	private def assertDuplicateSensors(Library library, String sensorName) {
		library.assertError(
			Literals.SENSOR,
			DeviceLibraryValidator.DUPLICATE_SENSOR,
			'''Duplicate sensor definition «sensorName» in same board'''
		)
	}
	
	@Test def void testMissingOverride() {
		'''
		package iot
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			sensor a pin(12) as p
		'''.parse.assertError(
			Literals.SENSOR,
			DeviceLibraryValidator.NON_OVERRIDING_SENSOR,
			"Redeclared sensor a must override inherited definition from parent"
		)
	}
	
	@Test def void testInvalidOverride() {
		'''
		package iot
		define board BoardA
			override sensor a
		'''.parse.assertError(
			Literals.SENSOR,
			null,
			"No such sensor a to override from parent"
		)
	}
	
	@Test def void testInvalidOverrideWithParent() {
		'''
		package iot
		define board BoardA
			sensor a pin(12) as p
		
		define board BoardB includes BoardA
			override sensor b
		'''.parse.assertError(
			Literals.SENSOR,
			null,
			"No such sensor b to override from parent"
		)
	}
}
