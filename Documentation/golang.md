# Golang

# Taking a trace of the program

```go
f, err := os.Create("/tmp/mytrace")
if err != nil {
    panic(err)
}
defer f.Close()
err = trace.Start(f)
if err != nil {
    panic(err)
}
defer trace.Stop()
```

# Time a piece of code

```go
start := time.Now()
// Code to measure
duration := time.Since(start)

// Formatted string, such as "2h3m0.5s" or "4.503μs"
fmt.Println(duration)
```

# Test maps

```go
tests := map[string]struct {
    kind     string
    value    string
    expected string
}{
    "secret":         {kind: "secret", value: "secret{{example}}", expected: "example"},
    "pipeline":       {kind: "pipeline", value: "pipeline{{example}}", expected: "example"},
    "run":            {kind: "run", value: "run{{example}}", expected: "example"},
    "incorrect_kind": {kind: "secret", value: "run{{example}}", expected: ""},
    "normal_value":   {kind: "secret", value: "normal_value", expected: ""},
}

for name, test := range tests {
    t.Run(name, func(t *testing.T) {
        result := parseInterpolationSyntax(test.kind, test.value)

        if result != test.expected {
            t.Errorf("incorrect interpolation result; want %s got %s", test.expected, result)
        }
    })
}
```

# You can tell go proxy to attempt to download the dependency directly

Great for testing things from branches

```bash
GOPROXY=direct go get -u github.com/clintjedwards/gofer/gofer_sdk/go@rust-rewrite
```
