package org.iot.devicefactory.generator.python

import com.google.inject.Inject
import org.iot.devicefactory.common.Add
import org.iot.devicefactory.common.And
import org.iot.devicefactory.common.BooleanLiteral
import org.iot.devicefactory.common.Conditional
import org.iot.devicefactory.common.Div
import org.iot.devicefactory.common.Equal
import org.iot.devicefactory.common.Exponent
import org.iot.devicefactory.common.GreaterThan
import org.iot.devicefactory.common.GreaterThanEqual
import org.iot.devicefactory.common.LessThan
import org.iot.devicefactory.common.LessThanEqual
import org.iot.devicefactory.common.Mul
import org.iot.devicefactory.common.Negation
import org.iot.devicefactory.common.Not
import org.iot.devicefactory.common.NumberLiteral
import org.iot.devicefactory.common.Or
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.common.Rem
import org.iot.devicefactory.common.StringLiteral
import org.iot.devicefactory.common.Sub
import org.iot.devicefactory.common.Tuple
import org.iot.devicefactory.common.Unequal
import org.iot.devicefactory.typing.ExpressionType
import org.iot.devicefactory.typing.ExpressionTypeChecker

class ExpressionGenerator {

	@Inject extension ExpressionTypeChecker

	def dispatch String compileExp(Conditional exp) {
		'''(«exp.first.compileExp» if «exp.condition.compileExp» else «exp.second.compileExp»)'''
	}

	def dispatch String compileExp(Or exp) {
		'''(«exp.left.compileExp» or «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(And exp) {
		'''(«exp.left.compileExp» and «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Equal exp) {
		'''(«exp.left.compileExp» == «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Unequal exp) {
		'''(«exp.left.compileExp» != «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(LessThan exp) {
		'''(«exp.left.compileExp» < «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(LessThanEqual exp) {
		'''(«exp.left.compileExp» <= «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(GreaterThan exp) {
		'''(«exp.left.compileExp» > «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(GreaterThanEqual exp) {
		'''(«exp.left.compileExp» >= «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Add exp) {
		val wrapLeft = exp.left.typeOf === ExpressionType.STRING
		val wrapRight = exp.right.typeOf === ExpressionType.STRING
		
		val left = '''«IF wrapLeft»str(«exp.left.compileExp»)«ELSE»«exp.left.compileExp»«ENDIF»'''
		val right = '''«IF wrapRight»str(«exp.right.compileExp»)«ELSE»«exp.right.compileExp»«ENDIF»'''
		
		'''(«left» + «right»)'''
	}

	def dispatch String compileExp(Sub exp) {
		'''(«exp.left.compileExp» - «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Mul exp) {
		'''(«exp.left.compileExp» * «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Div exp) {
		'''(«exp.left.compileExp» / «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Rem exp) {
		'''(«exp.left.compileExp» % «exp.right.compileExp»)'''
	}

	def dispatch String compileExp(Negation exp) {
		'''(-«exp.value.compileExp»)'''
	}

	def dispatch String compileExp(Exponent exp) {
		'''(«exp.base.compileExp» ** «exp.power.compileExp»)'''
	}

	def dispatch String compileExp(Not exp) {
		'''(not «exp.value.compileExp»)'''
	}

	def dispatch String compileExp(Tuple exp) {
		'''(«FOR v : exp.values SEPARATOR ", "»«v.compileExp»«ENDFOR»)'''
	}

	def dispatch String compileExp(NumberLiteral exp) {
		'''«IF exp.value.startsWith("-")»(«exp.value»)«ELSE»«exp.value»«ENDIF»'''
	}

	def dispatch String compileExp(BooleanLiteral exp) {
		'''«exp.value.toString.toFirstUpper»'''
	}

	def dispatch String compileExp(StringLiteral exp) {
		'''"«exp.value»"'''
	}

	def dispatch String compileExp(Reference exp) {
		'''_tuple.«exp.variable.name»'''
	}
}
