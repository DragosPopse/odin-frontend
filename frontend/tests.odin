package frontend

import test "core:testing"
import "core:path/filepath"
import "core:os"
import "core:strings"
import "core:fmt"

@test
test_tokenizer :: proc(T: ^test.T) {
    t: Tokenizer
    fullpath := filepath.join({ODIN_ROOT, "examples/demo/demo.odin"})
    data, ok := os.read_entire_file(fullpath)
    test.expect(T, ok, "File couldn't be read.")
    output_sb := strings.builder_make()
    src := string(data)
    tokenizer_init(&t, src, fullpath)

    for tok := tokenizer_scan(&t); tok.kind != .EOF; tok = tokenizer_scan(&t) {
        fmt.sbprintf(&output_sb, "%v[%v](%d:%d)\n", tok.text, tok.kind, tok.pos.line, tok.pos.column)
    }


    output, k := os.open("tokenizer_test.txt", os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    test.expect(T, k == 0, "Failed to write output.")
    os.write_string(output, strings.to_string(output_sb))
    test.expect(T, t.error_count == 0, "Tokenization failed with some errors.")
}
