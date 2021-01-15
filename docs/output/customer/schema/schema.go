// This file has been generated by go-spector; DO NOT EDIT.
package schema

import (
	"strings"
)

type ValidationError struct {
	err  error
	next *ValidationError
}

func (v *ValidationError) Append(err error) *ValidationError {
	if v.err == nil {
		v.err = err
		return v
	}

	return &ValidationError{
		err:  err,
		next: v,
	}
}

func (v *ValidationError) Error() string {
	var elems []string
	curr := v
	for {
		if curr == nil {
			break
		}
		elems = append(elems, curr.err.Error())
		curr = curr.next
	}

	return strings.Join(elems, "\n")
}

func (v *ValidationError) Is(err error) bool {
	curr := v
	for {
		if curr.err == err {
			return true
		}

		if curr.next == nil {
			return false
		}

		curr = curr.next
	}
}

func (v *ValidationError) Unwrap() error {
	return v.err
}
