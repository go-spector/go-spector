package main

import (
	"flag"
	"os"
	"text/template"

	internalTmpl "github.com/go-spector/go-spector/pkg/template"
)

type (
	Format = string
	Alias  = string
	Spec   struct {
		Routes []Route
	}
	Route struct {
		Name   string
		URI    string
		Method string
		Params []Param
		Model  Model
		Rules  []Rule
	}
	Param struct {
		Name     string
		Location string
	}
	Model struct {
		Name       string
		Attributes []Attribute
	}
	Attribute struct {
		Name     string
		Type     string
		Aliases  map[Format]Alias
		Optional bool
		Rules    []Rule
	}
	Rule struct {
		Name   string
		Values map[string]string
	}
)

type Component = string

const (
	client Component = "client"
	route  Component = "route"
	router Component = "router"
	schema Component = "schema"
	server Component = "server"
)

func main() {
	var (
		clientTmplFilename,
		routeTmplFilename,
		routerTmplFilename,
		schemaTmplFilename,
		serverTmplFilename string
	)

	flag.StringVar(&clientTmplFilename, "client", "configs/templates/client.tmpl", "...")
	flag.StringVar(&routeTmplFilename, "route", "configs/templates/route.tmpl", "...")
	flag.StringVar(&routerTmplFilename, "router", "configs/templates/router.tmpl", "...")
	flag.StringVar(&schemaTmplFilename, "schema", "configs/templates/schema.tmpl", "...")
	flag.StringVar(&serverTmplFilename, "server", "configs/templates/server.tmpl", "...")

	t := internalTmpl.New()
	t = template.Must(t.New(client).ParseFiles(clientTmplFilename))
	t = template.Must(t.New(route).ParseFiles(routeTmplFilename))
	t = template.Must(t.New(router).ParseFiles(routerTmplFilename))
	t = template.Must(t.New(schema).ParseFiles(schemaTmplFilename))
	t = template.Must(t.New("partials").ParseGlob("configs/templates/partials/*.tmpl"))
	t = template.Must(t.New("validations").ParseGlob("configs/templates/partials/validations/*"))
	t = template.Must(t.New(server).ParseFiles(serverTmplFilename))

	s := Spec{
		Routes: []Route{
			{
				Name: "AddUser",
				Params: []Param{
					{
						Name:     "authorization",
						Location: "header",
					},
				},
				Method: "Post",
				URI:    "/users/{id}",
				Model: Model{
					Name: "User",
					Attributes: []Attribute{
						{Name: "firstname", Type: "string", Aliases: map[string]string{"json": "firstname", "xml": "Firstname"}, Optional: true},
						{Name: "lastname", Type: "string", Aliases: map[string]string{"json": "lastname"}},
						{Name: "age", Type: "int", Aliases: map[string]string{"json": "age"}, Rules: []Rule{
							{Name: "default", Values: map[string]string{"default": "10"}},
							{Name: "enum", Values: map[string]string{"enum": "[]int{1,2,3,4,5}"}},
						}},
					},
				},
			},
		},
	}
	if err := t.ExecuteTemplate(os.Stdout, "schema.tmpl", s.Routes[0].Model); err != nil {
		panic(err)
	}

	if err := t.ExecuteTemplate(os.Stdout, "router.tmpl", s); err != nil {
		panic(err)
	}

	if err := t.ExecuteTemplate(os.Stdout, "route.tmpl", s.Routes[0]); err != nil {
		panic(err)
	}
}
