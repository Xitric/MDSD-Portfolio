package org.iot.devicefactory.tests.scoping

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.CommonPackage.Literals
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class CommonScopingTest {
	
	@Inject extension ParseHelper<Library>
	@Inject extension ScopingTestUtil
	
	private def parseWrapped(CharSequence text) {
		'''
		define board BoardA
			sensor a pin(12) as p
				preprocess «text»
		'''.parse.boards.get(0).sensors.get(0).preprocess.pipeline
	}
	
	@Test def void testSingleScope() {
		'''
		filter[true]
		'''.parseWrapped => [
			println(it)
		]
		
		'''
		map[0 => k].filter[true]
		'''.parseWrapped => [
			get(1).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k"]
			)
		]
	}
	
	@Test def void testTupleScope() {
		'''
		map[#(0, 0) => (k, l)].filter[true]
		'''.parseWrapped => [
			get(1).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
		]
	}
	
	@Test def void testFilterScopeUnchanged() {
		'''
		map[#(0, 0) => (k, l)].filter[true].filter[true]
		'''.parseWrapped => [
			get(1).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
			get(2).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
		]
	}
	
	@Test def void testMapScope() {
		'''
		map[#(0, 0) => (k, l)].filter[true].map[k + l => m].filter[true]
		'''.parseWrapped => [
			get(1).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
			get(3).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["m"]
			)
		]
	}
	
	@Test def void testWindowScopeUnchanged() {
		'''
		map[#(0, 0) => (k, l)].window[10].mean.filter[true]
		'''.parseWrapped => [
			get(2).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
		]
	}
	
	@Test def void testReferenceScopeInExpression() {
		'''
		map[(0, 0, 0) => (k, l, m)].filter[(0 + 5) / (k - 1 ** k) < 8]
		'''.parseWrapped => [
			(get(1) as Filter).expression.eAllOfType(Reference).forEach[
				assertScope(
					Literals.REFERENCE__VARIABLE,
					#["k", "l", "m"]
				)
			]
		]
	}
	
	@Test def void testReferenceRedefining() {
		'''
		map[true => k].map[k => k].filter[k]
		'''.parseWrapped => [
			((get(1) as Map).expression as Reference).variable.assertSame(
				(get(0) as Map).output
			)
			((get(2) as Filter).expression as Reference).variable.assertSame(
				(get(1) as Map).output
			)
		]
	}
}