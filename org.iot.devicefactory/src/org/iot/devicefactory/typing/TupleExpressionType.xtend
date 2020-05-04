package org.iot.devicefactory.typing

import java.util.Arrays

class TupleExpressionType extends ExpressionType {

	final ExpressionType[] elements;

	package new(ExpressionType... elements) {
		super(null)
		this.elements = elements
	}
	
	def getElements() {
		return elements
	}

	override equals(Object other) {
		if(! (other instanceof TupleExpressionType)) return false

		val otherTuple = other as TupleExpressionType
		Arrays.deepEquals(this.elements, otherTuple.elements)
	}

	override toString() {
		'''(«FOR element : elements SEPARATOR ", "»«element»«ENDFOR»)'''
	}
}
