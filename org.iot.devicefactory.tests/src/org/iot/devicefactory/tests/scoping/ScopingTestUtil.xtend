package org.iot.devicefactory.tests.scoping

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScopeProvider
import org.iot.devicefactory.common.Pipeline
import org.junit.Assert

class ScopingTestUtil {

	@Inject extension IScopeProvider

	def assertScope(EObject context, EReference reference, Iterable<CharSequence> expected) {
		context.getScope(reference).allElements.map[it.name.toString].iterEquals(expected)
	}

	def private <T> iterEquals(Iterable<? extends T> a, Iterable<? extends T> b) {
		Assert.assertTrue(
			'''Expected scope «b» but was «a»''',
			(a.forall[b.contains(it)] && a.size === b.size)
		)
	}
	
	def get(Pipeline pipeline, int index) {
		var current = pipeline
		for (var i = 0; i < index; i++) {
			current = current.next
		}
		return current
	}
}
