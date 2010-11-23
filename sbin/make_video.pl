

my $frame_rate = 10;
`ffmpeg -qscale 5 -r $frame_rate -b 9600 -i graph_WebBench_cpu_%06d.png movie.mp4`;
