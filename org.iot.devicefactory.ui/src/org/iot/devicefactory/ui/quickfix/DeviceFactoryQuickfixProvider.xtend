/*
 * generated by Xtext 2.20.0
 */
package org.iot.devicefactory.ui.quickfix

import com.google.inject.Inject
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue
import org.iot.devicefactory.deviceFactory.Language
import org.iot.devicefactory.generator.DeviceFactoryGenerator
import org.iot.devicefactory.validation.DeviceFactoryIssueCodes

/**
 * Custom quickfixes.
 *
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#quick-fixes
 */
class DeviceFactoryQuickfixProvider extends CommonQuickfixProvider {

	@Inject DeviceFactoryGenerator factoryGenerator

	@Fix(DeviceFactoryIssueCodes.SUPERFLUOUS_LIBRARY)
	def removePackageName(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Remove library statement', 'Remove unused library statement', null) [
			context |
			val document = context.xtextDocument
			//issue.lineNumber is 1-based
			val issueLineInfo = document.getLineInformation(issue.lineNumber - 1)
			document.replace(issueLineInfo.offset, issueLineInfo.length, "")
		]
	}
	
	@Fix(DeviceFactoryIssueCodes.UNSUPPORTED_LANGUAGE)
	def swapWithSupportedLanguage(Issue issue, IssueResolutionAcceptor acceptor) {
		for (String language : factoryGenerator.supportedLanguages) {
			acceptor.accept(issue, '''Change language to «language»''', '''Change language to «language»''', null) [
				element, context |
				(element as Language).name = language
			]
		}
	}
}
