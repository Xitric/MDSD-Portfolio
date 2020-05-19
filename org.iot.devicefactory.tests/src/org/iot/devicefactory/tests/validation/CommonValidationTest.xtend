package org.iot.devicefactory.tests.validation

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.iot.devicefactory.common.CommonPackage.Literals
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.tests.CommonInjectorProvider
import org.iot.devicefactory.validation.CommonIssueCodes
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

@ExtendWith(InjectionExtension)
@InjectWith(CommonInjectorProvider)
class CommonValidationTest {
	
	@Inject extension ParseHelper<Pipeline>
	@Inject extension ValidationTestHelper
	
	@Test def void testConditional() {
		'''
		filter[true ? true : false]
		'''.parse.assertNoErrors
		
		'''
		map[true ? 5 : 5e8 => a]
		'''.parse.assertNoErrors
		
		'''
		map[true ? 5.75 : 0x3b => a]
		'''.parse.assertNoErrors
		
		'''
		map[true ? "" : false => a]
		'''.parse.assertError(
			Literals.CONDITIONAL,
			null,
			"Expected string, got boolean"
		)
		
		'''
		map[5 ? "" : "" => a]
		'''.parse.assertError(
			Literals.CONDITIONAL,
			null,
			"Expected boolean, got integer"
		)
		
		'''
		map[true ? ("", 5) : (false, 5.6, "") => a]
		'''.parse.assertError(
			Literals.CONDITIONAL,
			null,
			"Expected (string, double, string), got (string, integer)"
		)
		
		'''
		map[true ? ("", 5) : (false, 5.6, "") => a]
		'''.parse.assertError(
			Literals.CONDITIONAL,
			null,
			"Expected (string, double, string), got (boolean, double, string)"
		)
	}
	
	@Test def void testOr() {
		'''
		filter[true || false]
		'''.parse.assertNoErrors
		
		'''
		filter[true || ""]
		'''.parse.assertError(
			Literals.OR,
			null,
			"Expected boolean, got string"
		)
		
		'''
		filter[0x6e || false]
		'''.parse.assertError(
			Literals.OR,
			null,
			"Expected boolean, got integer"
		)
		
		'''
		filter[true || ]
		'''.parse.assertError(
			Literals.OR,
			null,
			"Expected boolean, got nothing"
		)
	}
	
	@Test def void testUnequal() {
		'''
		filter[5 != 8.6]
		'''.parse.assertNoErrors
		
		'''
		filter[false != true]
		'''.parse.assertNoErrors
		
		'''
		filter["a" != "b"]
		'''.parse.assertNoErrors
		
		'''
		filter[(5, "", false) != (8e-2, "", true)]
		'''.parse.assertNoErrors
		
		'''
		filter[5 != ""]
		'''.parse.assertError(
			Literals.UNEQUAL,
			null,
			"Expected integer, got string"
		)
	}
	
	@Test def void testLessThanEqual() {
		'''
		filter[8.6 <= 5]
		'''.parse.assertNoErrors
		
		'''
		filter[true <= false]
		'''.parse.assertError(
			Literals.LESS_THAN_EQUAL,
			null,
			"Expected integer or double, got boolean"
		)
		
		'''
		filter[ <= 5]
		'''.parse.assertError(
			Literals.LESS_THAN_EQUAL,
			null,
			"Expected integer or double, got nothing"
		)
	}
	
	@Test def void testAdd() {
		'''
		map[5 + 8.6 => a]
		'''.parse.assertNoErrors
		
		'''
		map[5 + "" => a]
		'''.parse.assertNoErrors
		
		'''
		map["" + false => a]
		'''.parse.assertNoErrors
		
		'''
		map["" + (5, false) => a]
		'''.parse.assertNoErrors
		
		'''
		map[true + 5 => a]
		'''.parse.assertError(
			Literals.ADD,
			null,
			"Expected integer or double, got boolean"
		)
	}
	
	@Test def void testDiv() {
		'''
		map[5 / 8.3 => a]
		'''.parse.assertNoErrors
		
		'''
		map["" / 8.3 => a]
		'''.parse.assertError(
			Literals.DIV,
			null,
			"Expected integer or double, got string"
		)
		
		'''
		map[8.3 / true => a]
		'''.parse.assertError(
			Literals.DIV,
			null,
			"Expected integer or double, got boolean"
		)
	}
	
	@Test def void testNegation() {
		'''
		map[-8 => a]
		'''.parse.assertNoErrors
		
		'''
		map[-true => a]
		'''.parse.assertError(
			Literals.NEGATION,
			null,
			"Expected integer or double, got boolean"
		)
	}
	
	@Test def void testNot() {
		'''
		map[!false => a]
		'''.parse.assertNoErrors
		
		'''
		map[!"" => a]
		'''.parse.assertError(
			Literals.NOT,
			null,
			"Expected boolean, got string"
		)
	}
	
	@Test def void testTuple() {
		'''
		map[(5, "", false) => (a, b, c)]
		'''.parse.assertNoErrors
		
		'''
		map[(5, (0x3, ""), false) => (a, b, c)]
		'''.parse.assertError(
			Literals.TUPLE,
			null,
			"Tuples are only allowed at the top-level. This tuple contains a nested tuple: (integer, string)"
		)
	}
	
	@Test def void testFilter() {
		'''
		filter[true]
		'''.parse.assertNoErrors
		
		'''
		filter[5]
		'''.parse.assertError(
			Literals.FILTER,
			null,
			"Expected boolean, got integer"
		)
	}
	
	@Test def void testMap() {
		'''
		map[5 => a]
		'''.parse.assertNoErrors
		
		'''
		map[5 => (a, b)]
		'''.parse.assertError(
			Literals.MAP,
			null,
			"Expected output variable declaration to contain 1 variable, got 2"
		)
		
		'''
		map[(5, 2) => (a, b)]
		'''.parse.assertNoErrors
		
		'''
		map[(5, 2) => a]
		'''.parse.assertError(
			Literals.MAP,
			null,
			"Expected output variable declaration to contain 2 variables, got 1"
		)
	}
	
	@Test def void testWindow() {
		'''
		map[5 => a].window[10].mean
		'''.parse.assertNoErrors
		
		'''
		map[5e8 => a].window[10].mean
		'''.parse.assertNoErrors
		
		'''
		map[true => a].window[10].mean
		'''.parse.assertError(
			Literals.WINDOW,
			CommonIssueCodes.ILLEGAL_WINDOW_INPUT,
			"Window operations are only applicable on integer or double types, but is called on boolean"
		)
		
		'''
		map["Hello, world!" => a].window[10].mean
		'''.parse.assertError(
			Literals.WINDOW,
			CommonIssueCodes.ILLEGAL_WINDOW_INPUT,
			"Window operations are only applicable on integer or double types, but is called on string"
		)
		
		'''
		map[(5, 5e8) => (a, b)].window[10].mean
		'''.parse.assertNoErrors
		
		'''
		map[(5, true) => a].window[10].mean
		'''.parse.assertError(
			Literals.WINDOW,
			CommonIssueCodes.ILLEGAL_WINDOW_INPUT,
			"Window operations are only applicable on integer or double types, but is called on (integer, boolean)"
		)
	}
}
