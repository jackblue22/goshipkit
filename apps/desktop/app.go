package main

import "context"

type App struct {
	ctx context.Context
}

func NewApp() *App { return &App{} }

func (a *App) Startup(ctx context.Context) { a.ctx = ctx }

func (a *App) APIBaseURL() string { return "http://localhost:8080" }
