package org.iot.devicefactory.util

import com.google.common.collect.Iterables
import java.util.Collections
import org.eclipse.xtext.naming.QualifiedName

class QualifiedNameUtils {
	
	static def matches(QualifiedName me, QualifiedName other) {
		val meSkipped = me.lastSegment == "*" ? me.skipLast(1) : me

		if (meSkipped.segmentCount > other.segmentCount) {
			return false
		}

		for (var i = 0; i < meSkipped.segmentCount; i++) {
			if (meSkipped.getSegment(i) != other.getSegment(i)) {
				return false
			}
		}

		return true
	}
	
	static def prepend(QualifiedName original, String prefix) {
		val originalNameSegments = original.segments
		val prefixedSegments = Iterables.concat(Collections.singleton(prefix), originalNameSegments)
		QualifiedName.create(prefixedSegments)
	}
}
