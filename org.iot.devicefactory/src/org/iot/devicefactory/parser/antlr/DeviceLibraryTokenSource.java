/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.parser.antlr;

import org.antlr.runtime.Token;
import org.antlr.runtime.TokenSource;
import org.eclipse.xtext.parser.antlr.AbstractIndentationTokenSource;
import org.iot.devicefactory.parser.antlr.internal.InternalDeviceLibraryParser;

public class DeviceLibraryTokenSource extends AbstractIndentationTokenSource {

	public DeviceLibraryTokenSource(TokenSource delegate) {
		super(delegate);
	}

	@Override
	protected boolean shouldSplitTokenImpl(Token token) {
		// TODO Review assumption
		return token.getType() == InternalDeviceLibraryParser.RULE_WS;
	}

	@Override
	protected int getBeginTokenType() {
		// TODO Review assumption
		return InternalDeviceLibraryParser.RULE_BEGIN;
	}

	@Override
	protected int getEndTokenType() {
		// TODO Review assumption
		return InternalDeviceLibraryParser.RULE_END;
	}

}
