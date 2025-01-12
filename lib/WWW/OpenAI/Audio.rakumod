use v6.d;

use WWW::OpenAI::Request;

unit module WWW::OpenAI::Audio;

#============================================================
# Audio
#============================================================

#| OpenAI image generation access.
our proto OpenAIAudio($fileName,
                      :$type = 'transcriptions',
                      :$temperature is copy = Whatever,
                      :$language is copy = Whatever,
                      :$model is copy = Whatever,
                      Str :$prompt = '',
                      :$auth-key is copy = Whatever,
                      UInt :$timeout= 10,
                      :$format is copy = Whatever,
                      Str :$method = 'tiny'
                      ) is export {*}

#| OpenAI image generation access.
multi sub OpenAIAudio(@fileNames, *%args) {
    return @fileNames.map({ OpenAIAudio($_, |%args) });
}

#| OpenAI image generation access.
multi sub OpenAIAudio($file,
                      :$type is copy = 'transcriptions',
                      :$temperature is copy = Whatever,
                      :$language is copy = Whatever,
                      :$model is copy = Whatever,
                      Str :$prompt = '',
                      :$auth-key is copy = Whatever,
                      UInt :$timeout= 10,
                      :$format is copy = Whatever,
                      Str :$method = 'tiny') {

    #------------------------------------------------------
    # Process file name
    #------------------------------------------------------

    # Verify file exists
    die "The file '$file' does not exists"
    unless $file.IO.e;

    #------------------------------------------------------
    # Process type
    #------------------------------------------------------
    if $type.isa(Whatever) { $type = 'transcriptions'; }
    my @expectedTypes = <transcriptions translations>;
    die "The value of the argument \$type is expected to be one of { @expectedTypes.join(', ') }."
    unless $type ~~ Str && $type.lc ∈ @expectedTypes;

    #------------------------------------------------------
    # Process format
    #------------------------------------------------------
    my @expectedFormats = <json text srt verbose_json vtt>;
    die "The value of the argument \$format is expected to be one of { @expectedFormats.join(', ') }."
    unless $format ~~ Str && $format.lc ∈ @expectedFormats;

    #------------------------------------------------------
    # Process $temperature
    #------------------------------------------------------
    if $temperature.isa(Whatever) { $temperature = 0; }
    die "The argument \$temperature is expected to be Whatever or number between 0 and 1."
    unless $temperature ~~ Numeric && 0 ≤ $temperature ≤ 1;

    #------------------------------------------------------
    # Process $language
    #------------------------------------------------------
    if $language.isa(Whatever) { $language = ''; }

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------
    # The API documentation states that only 'whisper-1' is available. (2023-03-29)
    if $model.isa(Whatever) { $model = 'whisper-1'; }

    #------------------------------------------------------
    # Make OpenAI URL
    #------------------------------------------------------

    my $url = 'https://api.openai.com/v1/audio/' ~ $type;

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    if $method eq 'curl' {
        # Some sort of no-good shortcut -- see curl-post
        my %body = %(:$file, :$model, :$prompt, :$language, :$temperature, response_format => $format);

        return openai-request(:$url, :%body, :$auth-key, :$timeout, :$format, :$method);

    } elsif $method eq 'tiny' {

        my %body = :$model, :$temperature, response_format => $format;

        if $prompt { %body<prompt> = $prompt; }

        if $language { %body<language> = $language; }

        %body<file> = $file.IO;

        return openai-request(:$url, :%body, :$auth-key, :$timeout, :$format, :$method);

    }
}
