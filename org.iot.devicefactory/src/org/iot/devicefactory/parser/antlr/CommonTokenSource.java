/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.parser.antlr;

import org.antlr.runtime.Token;
import org.antlr.runtime.TokenSource;
import org.eclipse.xtext.parser.antlr.AbstractIndentationTokenSource;
import org.iot.devicefactory.parser.antlr.internal.InternalCommonParser;

public class CommonTokenSource extends AbstractIndentationTokenSource {

	public CommonTokenSource(TokenSource delegate) {
		super(delegate);
	}

	@Override
	protected boolean shouldSplitTokenImpl(Token token) {
		// TODO Review assumption
		return token.getType() == InternalCommonParser.RULE_WS;
	}

	@Override
	protected int getBeginTokenType() {
		// TODO Review assumption
		return InternalCommonParser.RULE_BEGIN;
	}

	@Override
	protected int getEndTokenType() {
		// TODO Review assumption
		return InternalCommonParser.RULE_END;
	}

}
