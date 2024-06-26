import file_streams/read_stream
import file_streams/read_stream_error
import gleam/bit_array
import gleam/string
import gleeunit/should
import simplifile

pub fn read_stream_test() {
  let tmp_file_name = "read_stream_test"

  let assert Ok(Nil) =
    simplifile.write_bits(
      tmp_file_name,
      bit_array.concat([
        <<-100:int-size(8), 200:int-size(8)>>,
        // 16-bit integers
        <<
          -3000:little-int-size(16), -3000:big-int-size(16),
          10_000:little-int-size(16), 10_000:big-int-size(16),
        >>,
        // 32-bit integers
        <<
          -300_000:little-int-size(32), -300_000:big-int-size(32),
          1_000_000:little-int-size(32), 1_000_000:big-int-size(32),
        >>,
        // 64-bit integers
        <<
          -10_000_000_000:little-int-size(64), -10_000_000_000:big-int-size(64),
          100_000_000_000:little-int-size(64), 100_000_000_000:big-int-size(64),
        >>,
        // 32-bit floats
        <<
          1.5:little-float-size(32), 1.5:big-float-size(32),
          2.5:little-float-size(64), 2.5:big-float-size(64),
        >>,
        // 64-bit floats
        <<
          1.0:little-float-size(64), 2.0:little-float-size(64),
          3.0:little-float-size(64), 4.0:little-float-size(64),
        >>,
        bit_array.from_string(string.repeat("abc123", 10_000)),
      ]),
    )

  let assert Ok(rs) = read_stream.open(tmp_file_name)

  read_stream.read_int8(rs)
  |> should.equal(Ok(-100))

  read_stream.read_uint8(rs)
  |> should.equal(Ok(200))

  read_stream.read_int16_le(rs)
  |> should.equal(Ok(-3000))
  read_stream.read_int16_be(rs)
  |> should.equal(Ok(-3000))

  read_stream.read_uint16_le(rs)
  |> should.equal(Ok(10_000))
  read_stream.read_uint16_be(rs)
  |> should.equal(Ok(10_000))

  read_stream.read_int32_le(rs)
  |> should.equal(Ok(-300_000))
  read_stream.read_int32_be(rs)
  |> should.equal(Ok(-300_000))

  read_stream.read_uint32_le(rs)
  |> should.equal(Ok(1_000_000))
  read_stream.read_uint32_be(rs)
  |> should.equal(Ok(1_000_000))

  read_stream.read_int64_le(rs)
  |> should.equal(Ok(-10_000_000_000))
  read_stream.read_int64_be(rs)
  |> should.equal(Ok(-10_000_000_000))

  read_stream.read_uint64_le(rs)
  |> should.equal(Ok(100_000_000_000))
  read_stream.read_uint64_be(rs)
  |> should.equal(Ok(100_000_000_000))

  read_stream.read_float32_le(rs)
  |> should.equal(Ok(1.5))
  read_stream.read_float32_be(rs)
  |> should.equal(Ok(1.5))

  read_stream.read_float64_le(rs)
  |> should.equal(Ok(2.5))
  read_stream.read_float64_be(rs)
  |> should.equal(Ok(2.5))

  read_stream.read_list(rs, read_stream.read_float64_le, 4)
  |> should.equal(Ok([1.0, 2.0, 3.0, 4.0]))

  case read_stream.read_to_eof(rs) {
    Ok(rest) -> {
      bit_array.to_string(rest)
      |> should.equal(Ok(string.repeat("abc123", 10_000)))
      Nil
    }
    Error(_) -> should.fail()
  }

  read_stream.read_bytes_exact(rs, 1)
  |> should.equal(Error(read_stream_error.EndOfStream))

  read_stream.close(rs)
  |> should.equal(Ok(Nil))

  let assert Ok(Nil) = simplifile.delete(tmp_file_name)
}
