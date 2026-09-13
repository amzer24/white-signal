# Audio shutdown warning investigation

The fixed-FPS opening input playthrough returned zero failures but verbose shutdown reported OggPacketSequence, AudioStreamPlaybackOggVorbis and AudioStreamPlaybackWAV instances. A rendered Drowned capture did not reproduce on the diagnostic rerun.

Controlled probe: leave gameplay and audio source unchanged; after queue_free, await a frame and allow 20 ten-millisecond wall-clock intervals, yielding a process frame each time. The opening playthrough still returned zero failures and reported no leaked objects or resources in use. The sandbox certificate-store error remains unrelated.

The opening harness now permits this bounded audio cleanup before quitting. This is evidence for asynchronous audio teardown at accelerated test shutdown, not evidence of a gameplay node leak or proof that every shutdown path is clean. No runtime audio changes were made. Full music listening and standalone playthrough remain release gates.
