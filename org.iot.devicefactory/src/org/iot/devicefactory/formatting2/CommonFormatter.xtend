/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.formatting2

import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.formatting2.AbstractFormatter2
import org.eclipse.xtext.formatting2.IFormattableDocument
import org.eclipse.xtext.formatting2.ITextReplacer
import org.eclipse.xtext.formatting2.ITextReplacerContext
import org.eclipse.xtext.formatting2.regionaccess.ISemanticRegion
import org.iot.devicefactory.common.Add
import org.iot.devicefactory.common.And
import org.iot.devicefactory.common.CommonPackage.Literals
import org.iot.devicefactory.common.Conditional
import org.iot.devicefactory.common.Div
import org.iot.devicefactory.common.Equal
import org.iot.devicefactory.common.ExecutePipeline
import org.iot.devicefactory.common.Exponent
import org.iot.devicefactory.common.Expression
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.GreaterThan
import org.iot.devicefactory.common.GreaterThanEqual
import org.iot.devicefactory.common.LessThan
import org.iot.devicefactory.common.LessThanEqual
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Mul
import org.iot.devicefactory.common.Negation
import org.iot.devicefactory.common.Not
import org.iot.devicefactory.common.NumberLiteral
import org.iot.devicefactory.common.Or
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.Rem
import org.iot.devicefactory.common.StringLiteral
import org.iot.devicefactory.common.Sub
import org.iot.devicefactory.common.Tuple
import org.iot.devicefactory.common.Unequal
import org.iot.devicefactory.common.Variables
import org.iot.devicefactory.common.Window

class CommonFormatter extends AbstractFormatter2 {

	def dispatch void format(Filter filter, extension IFormattableDocument document) {
		filter.next.format
		filter.formatPipelineParentheses(document)
		filter.expression.format
	}

	def dispatch void format(Map map, extension IFormattableDocument document) {
		map.next.format
		map.formatPipelineParentheses(document)
		map.expression.format
		
		map.regionFor.keyword("=>").surround[oneSpace]
		
		map.output.format
	}

	def dispatch void format(Window window, extension IFormattableDocument document) {
		window.next.format
		window.formatPipelineParentheses(document)
		window.execute.surround[noSpace]
	}
	
	private def void formatPipelineParentheses(Pipeline pipeline, extension IFormattableDocument document) {
		val dotRegion = pipeline.regionFor.keyword(".")
		if (dotRegion !== null && !(dotRegion.nextSemanticRegion.semanticElement instanceof ExecutePipeline)) {
			val begin = dotRegion.previousHiddenRegion
			val end = pipeline.regionFor.keyword("]").previousHiddenRegion
			document.set(begin, [newLine])
			document.set(begin, end, [indent])
		}

		dotRegion.surround[noSpace]
		pipeline.regionFor.keyword("[").surround[noSpace]
		pipeline.regionFor.keyword("]").surround[noSpace]
	}

	def dispatch void format(Conditional conditional, extension IFormattableDocument document) {
		conditional.formatParentheses(document)
		conditional.condition.format
		conditional.first.format
		conditional.second.format
		
		conditional.regionFor.keyword("?").surround[oneSpace]
		conditional.regionFor.keyword(":").surround[oneSpace]
	}

	def dispatch void format(Or or, extension IFormattableDocument document) {
		or.formatParentheses(document)
		or.regionFor.keyword("||").surround[oneSpace]
		or.left.format
		or.right.format
	}

	def dispatch void format(And and, extension IFormattableDocument document) {
		and.formatParentheses(document)
		and.regionFor.keyword("&&").surround[oneSpace]
		and.left.format
		and.right.format
	}

	def dispatch void format(Equal equal, extension IFormattableDocument document) {
		equal.formatParentheses(document)
		equal.regionFor.keyword("==").surround[oneSpace]
		equal.left.format
		equal.right.format
	}

	def dispatch void format(Unequal unequal, extension IFormattableDocument document) {
		unequal.formatParentheses(document)
		unequal.regionFor.keyword("!=").surround[oneSpace]
		unequal.left.format
		unequal.right.format
	}

	def dispatch void format(LessThan lessThan, extension IFormattableDocument document) {
		lessThan.formatParentheses(document)
		lessThan.regionFor.keyword("<").surround[oneSpace]
		lessThan.left.format
		lessThan.right.format
	}

	def dispatch void format(LessThanEqual lessThanEqual, extension IFormattableDocument document) {
		lessThanEqual.formatParentheses(document)
		lessThanEqual.regionFor.keyword("<=").surround[oneSpace]
		lessThanEqual.left.format
		lessThanEqual.right.format
	}

	def dispatch void format(GreaterThan greaterThan, extension IFormattableDocument document) {
		greaterThan.formatParentheses(document)
		greaterThan.regionFor.keyword(">").surround[oneSpace]
		greaterThan.left.format
		greaterThan.right.format
	}

	def dispatch void format(GreaterThanEqual greaterThanEqual, extension IFormattableDocument document) {
		greaterThanEqual.formatParentheses(document)
		greaterThanEqual.regionFor.keyword(">=").surround[oneSpace]
		greaterThanEqual.left.format
		greaterThanEqual.right.format
	}

	def dispatch void format(Add add, extension IFormattableDocument document) {
		add.formatParentheses(document)
		add.regionFor.keyword("+").surround[oneSpace]
		add.left.format
		add.right.format
	}

	def dispatch void format(Sub sub, extension IFormattableDocument document) {
		sub.formatParentheses(document)
		sub.regionFor.keyword("-").surround[oneSpace]
		sub.left.format
		sub.right.format
	}

	def dispatch void format(Mul mul, extension IFormattableDocument document) {
		mul.formatParentheses(document)
		mul.regionFor.keyword("*").surround[oneSpace]
		mul.left.format
		mul.right.format
	}

	def dispatch void format(Div div, extension IFormattableDocument document) {
		div.formatParentheses(document)
		div.regionFor.keyword("/").surround[oneSpace]
		div.left.format
		div.right.format
	}
	
	def dispatch void format(Rem rem, extension IFormattableDocument document) {
		rem.formatParentheses(document)
		rem.regionFor.keyword("%").surround[oneSpace]
		rem.left.format
		rem.right.format
	}

	def dispatch void format(Negation negation, extension IFormattableDocument document) {
		negation.formatParentheses(document)
		negation.regionFor.keyword("-").append[noSpace]
		negation.value.format
	}

	def dispatch void format(Exponent exponent, extension IFormattableDocument document) {
		exponent.formatParentheses(document)
		exponent.regionFor.keyword("**").surround[oneSpace]
		exponent.base.format
		exponent.power.format
	}

	def dispatch void format(Not not, extension IFormattableDocument document) {
		not.formatParentheses(document)
		not.regionFor.keyword("!").append[noSpace]
		not.value.format
	}

	def dispatch void format(Tuple tuple, extension IFormattableDocument document) {
		tuple.formatParentheses(document)
		tuple.regionFor.keywords(",").forEach[prepend[noSpace].append[oneSpace]]
		tuple.values.forEach[format]
	}
	
	private def formatParentheses(EObject obj, extension IFormattableDocument document) {
		val leftRegion = obj.regionFor.keyword("(")
		if (leftRegion !== null) {
			leftRegion.immediatelyFollowing.keyword("[").prepend[noSpace]
			leftRegion.immediatelyFollowing.keyword("(").prepend[noSpace]
			leftRegion.append[noSpace]
		}
		
		val rightRegion = obj.regionFor.keyword(")")
		if (rightRegion !== null) {
			rightRegion.immediatelyPreceding.keyword("]").append[noSpace]
			rightRegion.immediatelyPreceding.keyword(")").append[noSpace]
			rightRegion.prepend[noSpace]
		}
	}
	
	def dispatch void format(Variables variables, extension IFormattableDocument document) {
		variables.regionFor.keyword("(").prepend[oneSpace].append[noSpace]
		variables.regionFor.keyword(")").prepend[noSpace]
		variables.regionFor.keywords(",").forEach[prepend[noSpace].append[oneSpace]]
	}
	
	// Formatter never seemed to hit literals, so I catch them like this
	def dispatch void format(Expression expression, extension IFormattableDocument document) {
		expression.formatParentheses(document)
		
		switch expression {
			StringLiteral: {
				//TODO: Can we make this work?
				expression.regionFor.keywords("'").forEach[document.addReplacer(new QuotationReplacer(it))]
			}
			NumberLiteral: {
				if (expression.value.contains("e")) {
					val numberRegion = expression.regionFor.feature(Literals.NUMBER_LITERAL__VALUE)
					document.addReplacer(new ScientificReplacer(numberRegion))
				}
			}
		}
	}
	
	static class QuotationReplacer implements ITextReplacer {
		
		final ISemanticRegion quotationRegion
		
		new(ISemanticRegion quotationRegion) {
			this.quotationRegion = quotationRegion
		}
		
		override createReplacements(ITextReplacerContext context) {
			val replacement = quotationRegion.replaceWith('"')
			context.addReplacement(replacement)
			return context
		}
		
		override getRegion() {
			quotationRegion
		}
	}
	
	static class ScientificReplacer implements ITextReplacer {
		
		final ISemanticRegion scientificRegion
		
		new(ISemanticRegion scientificRegion) {
			this.scientificRegion = scientificRegion
		}
		
		override createReplacements(ITextReplacerContext context) {
			val newNumber = scientificRegion.text.replace('e', 'E')
			val replacement = scientificRegion.replaceWith(newNumber)
			context.addReplacement(replacement)
			return context
		}
		
		override getRegion() {
			scientificRegion
		}
	}
}
