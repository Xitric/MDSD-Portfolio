package org.iot.devicefactory.tests.scoping

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.CommonPackage.Literals
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.tests.CommonInjectorProvider
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(CommonInjectorProvider)
class CommonScopingTest {
	
	@Inject extension ParseHelper<Pipeline>
	@Inject extension ScopingTestUtil
	
	@Test def void testSingleScope() {
		'''
		map[0 => k].filter[true]
		'''.parse => [
			get(1).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k"]
			)
		]
	}
	
	@Test def void testTupleScope() {
		'''
		map[#(0, 0) => (k, l)].filter[true]
		'''.parse => [
			get(1).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
		]
	}
	
	@Test def void testFilterScopeUnchanged() {
		'''
		map[#(0, 0) => (k, l)].filter[true].filter[true]
		'''.parse => [
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
		'''.parse => [
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
		'''.parse => [
			get(2).assertScope(
				Literals.REFERENCE__VARIABLE,
				#["k", "l"]
			)
		]
	}
	
	@Test def void testReferenceScopeInExpression() {
		'''
		map[(0, 0, 0) => (k, l, m)].filter[(0 + 5) / (k - 1 ** k) < 8]
		'''.parse => [
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
		'''.parse => [
			((get(1) as Map).expression as Reference).variable.assertSame(
				(get(0) as Map).output
			)
			((get(2) as Filter).expression as Reference).variable.assertSame(
				(get(1) as Map).output
			)
		]
	}
}
