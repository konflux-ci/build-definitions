package main

import (
	"fmt"
	"os"
)

func expect(err error) {
	if err == nil {
		return
	}
	fmt.Fprint(os.Stderr, err)
	os.Exit(1)
}

func expectValue[T any](val T, err error) T {
	if err != nil {
		expect(err)
	}

	return val
}
