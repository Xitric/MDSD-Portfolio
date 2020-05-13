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
class DeviceFactoryImportValidationTest {
	
	@Inject extension ParseHelper<Deployment>
	@Inject extension ValidationTestHelper
	@Inject extension TestUtil
	
	@Test def void testIllegalBoardReference() {
		'''
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse.assertError(
			Literals.BASE_DEVICE,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Board 'esp32'"
		)
	}
	
	@Test def void testFullyQualifiedBoard() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		language python
		channel endpoint
		device controller board iot.boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testImportedBoard() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.esp32
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testWildcardImport() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.boards.*
		language python
		channel endpoint
		device controller board esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testPackageImport() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot.*
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}
	
	@Test def void testPackageImportNoWildcard() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library iot
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.BASE_DEVICE,
			Diagnostic.LINKING_DIAGNOSTIC,
			"Couldn't resolve reference to Board 'boards.esp32'"
		)
	}
	
	@Test def void testUnknownImport() {
		val resourceSet = makePackagedBoardLibrary()
		
		'''
		library ioot
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertError(
			Literals.LIBRARY,
			DeviceFactoryIssueCodes.SUPERFLUOUS_LIBRARY,
			"No resource found with qualified name ioot"
		)
	}
	
	@Test def void testSuperfluousImport() {
		val resourceSet = makeRootBoardLibrary()
		
		'''
		library esp32
		language python
		channel endpoint
		device controller board boards.esp32
			sensor barometer sample signal
				data raw_pressure
					out endpoint
		'''.parse(resourceSet).assertWarning(
			Literals.LIBRARY,
			DeviceFactoryIssueCodes.SUPERFLUOUS_LIBRARY,
			"Unnecessary import of library esp32 has no effect"
		)
	}
}
