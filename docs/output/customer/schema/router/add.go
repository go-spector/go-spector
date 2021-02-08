// This file has been generated by go-spector; DO NOT EDIT.
package router

import (
	"context"
	"encoding/json"
	"encoding/xml"
	"errors"
	"github.com/go-spector/go-spector/docs/output/customer/schema"
	"net/http"
	"strings"
)

type AddHandler http.HandlerFunc

func NewAddHandler(fn http.HandlerFunc) AddHandler {
	return AddHandler(fn)
}

func (h AddHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	err := h.DecodeCustomer(r)
	if v := (&schema.ValidationError{}); errors.As(err, &v) {
		w.WriteHeader(http.StatusUnprocessableEntity)
		if err := json.NewEncoder(w).Encode(v); err != nil {
			w.WriteHeader(http.StatusInternalServerError)
		}
		return
	}
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	h(w, r)
}

func (h AddHandler) DecodeCustomer(r *http.Request) error {
	c := &schema.Customer{}

	switch contentType := r.Header.Get("Content-Type"); {
	case strings.Contains(contentType, "xml"):
		if err := xml.NewDecoder(r.Body).Decode(c); err != nil {
			return err
		}
	default:
		if err := json.NewDecoder(r.Body).Decode(c); err != nil {
			return err
		}
	}

	if err := c.Validate(); err != nil {
		return err
	}

	r = r.WithContext(context.WithValue(r.Context(), schema.CustomerKey, c))
	return nil
}