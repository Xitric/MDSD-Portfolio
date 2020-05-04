package org.iot.devicefactory.typing

class ExpressionType {

	public static val INTEGER = new ExpressionType("integer")
	public static val DOUBLE = new ExpressionType("double")
	public static val BOOLEAN = new ExpressionType("boolean")
	public static val STRING = new ExpressionType("string")

	static def ExpressionType TUPLE(ExpressionType... elements) {
		new TupleExpressionType(elements)
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
