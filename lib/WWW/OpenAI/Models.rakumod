use v6.d;

use WWW::OpenAI::Request;
use HTTP::Tiny;
use JSON::Fast;

unit module WWW::OpenAI::Models;


#============================================================
# Known models
#============================================================
# https://platform.openai.com/docs/api-reference/models/list

my $knownModels = Set.new(["ada", "ada:2020-05-03", "ada-code-search-code",
                           "ada-code-search-text", "ada-search-document", "ada-search-query",
                           "ada-similarity", "babbage", "babbage:2020-05-03",
                           "babbage-code-search-code", "babbage-code-search-text",
                           "babbage-search-document", "babbage-search-query",
                           "babbage-similarity", "code-cushman-001", "code-davinci-002",
                           "code-davinci-edit-001", "code-search-ada-code-001",
                           "code-search-ada-text-001", "code-search-babbage-code-001",
                           "code-search-babbage-text-001", "curie", "curie:2020-05-03",
                           "curie-instruct-beta", "curie-search-document", "curie-search-query",
                           "curie-similarity", "cushman:2020-05-03", "davinci",
                           "davinci:2020-05-03", "davinci-if:3.0.0", "davinci-instruct-beta",
                           "davinci-instruct-beta:2.0.0", "davinci-search-document",
                           "davinci-search-query", "davinci-similarity", "gpt-3.5-turbo",
                           "gpt-3.5-turbo-0301", "gpt-4", "gpt-4-0314", "gpt-4-32k-0314",
                           "if-curie-v2", "if-davinci:3.0.0",
                           "if-davinci-v2", "text-ada-001", "text-ada:001", "text-babbage-001",
                           "text-babbage:001", "text-curie-001", "text-curie:001",
                           "text-davinci-001", "text-davinci:001", "text-davinci-002",
                           "text-davinci-003", "text-davinci-edit-001",
                           "text-davinci-insert-001", "text-davinci-insert-002",
                           "text-embedding-ada-002", "text-search-ada-doc-001",
                           "text-search-ada-query-001", "text-search-babbage-doc-001",
                           "text-search-babbage-query-001", "text-search-curie-doc-001",
                           "text-search-curie-query-001", "text-search-davinci-doc-001",
                           "text-search-davinci-query-001", "text-similarity-ada-001",
                           "text-similarity-babbage-001", "text-similarity-curie-001",
                           "text-similarity-davinci-001", "whisper-1"]);


our sub openai-known-models() is export {
    return $knownModels;
}

#============================================================
# Compatibility of models and end-points
#============================================================

# Taken from:
# https://platform.openai.com/docs/models/model-endpoint-compatibility

my %endPointToModels =
        '/v1/chat/completions' => <gpt-4 gpt-4-0314 gpt-4-32k gpt-4-32k-0314 gpt-3.5-turbo gpt-3.5-turbo-0301>,
        '/v1/completions' => <text-davinci-003 text-davinci-002 text-curie-001 text-babbage-001 text-ada-001>,
        '/v1/edits' => <text-davinci-edit-001 code-davinci-edit-001>,
        '/v1/audio/transcriptions' => <whisper-1>,
        '/v1/audio/translations' => <whisper-1>,
        '/v1/fine-tunes' => <davinci curie babbage ada>,
        '/v1/embeddings' => <text-embedding-ada-002 text-search-ada-doc-001>,
        '/v1/moderations' => <text-moderation-stable text-moderation-latest>;

#| End-point to models retrieval.
proto sub openai-end-point-to-models(|) is export {*}

multi sub openai-end-point-to-models() {
    return %endPointToModels;
}

multi sub openai-end-point-to-models(Str $endPoint) {
    return %endPointToModels{$endPoint};
}

#| Checks if a given string an identifier of a chat completion model.
proto sub openai-is-chat-completion-model($model) is export {*}

multi sub openai-is-chat-completion-model(Str $model) {
    return $model ∈ openai-end-point-to-models{'/v1/chat/completions'};
}

#| Checks if a given string an identifier of a text completion model.
proto sub openai-is-text-completion-model($model) is export {*}

multi sub openai-is-text-completion-model(Str $model) {
    return $model ∈ openai-end-point-to-models{'/v1/completions'};
}

#------------------------------------------------------------
# Invert to get model-to-end-point correspondence.
# At this point (2023-04-14) only the model "whisper-1" has more than one end-point.
my %modelToEndPoints = %endPointToModels.map({ $_.value.Array X=> $_.key }).flat.classify({ $_.key }).map({ $_.key => $_.value>>.value.Array });

#| Model to end-points retrieval.
proto sub openai-model-to-end-points(|) is export {*}

multi sub openai-model-to-end-points() {
    return %modelToEndPoints;
}

multi sub openai-model-to-end-points(Str $model) {
    return %modelToEndPoints{$model};
}

#============================================================
# Models
#============================================================

#| OpenAI models.
our sub OpenAIModels(:$auth-key is copy = Whatever, UInt :$timeout = 10) is export {
    #------------------------------------------------------
    # Process $auth-key
    #------------------------------------------------------
    # This code is repeated below.
    if $auth-key.isa(Whatever) {
        if %*ENV<OPENAI_API_KEY>:exists {
            $auth-key = %*ENV<OPENAI_API_KEY>;
        } else {
            note 'Cannot find OpenAI authorization key. ' ~
                    'Please provide a valid key to the argument auth-key, or set the ENV variable OPENAI_API_KEY.';
            $auth-key = ''
        }
    }
    die "The argument auth-key is expected to be a string or Whatever."
    unless $auth-key ~~ Str;

    #------------------------------------------------------
    # Retrieve
    #------------------------------------------------------
    my Str $url = 'https://api.openai.com/v1/models';

    my $resp = HTTP::Tiny.get: $url,
            headers => { authorization => "Bearer $auth-key" };

    my $res = from-json($resp<content>.decode);

    return $res<data>.map(*<id>).sort;
}
