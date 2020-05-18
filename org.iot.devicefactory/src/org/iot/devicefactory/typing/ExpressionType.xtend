package org.iot.devicefactory.typing

import java.util.Arrays

class ExpressionType {

	public static val INTEGER = new ExpressionType("integer")
	public static val DOUBLE = new ExpressionType("double")
	public static val BOOLEAN = new ExpressionType("boolean")
	public static val STRING = new ExpressionType("string")
	public static val VOID = new ExpressionType("void")

	static def ExpressionType TUPLE(ExpressionType... elements) {
		new TupleExpressionType(elements)
	}
	
	static def ExpressionType TUPLE(ExpressionType element, int repeat) {
		val ExpressionType[] type = ArrayLiterals.newArrayOfSize(repeat)
		Arrays.fill(type, element)
		TUPLE(type)
	}

	final String tag;

	package new(String tag) {
		this.tag = tag
	}
	
	override equals(Object other) {
		return this === other || (this === INTEGER && other === DOUBLE)
	}

	override String toString() {
		tag
	}
}
