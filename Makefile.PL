use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Modify Email::MIME Objects Easily",
               NAME          => 'Email::MIME::Modifier',
               PREREQ_PM     => {
                                 'Email::MIME' => '1.7',
                                 'Email::MIME::ContentType' => '1.0',
                                 'Email::MIME::Encodings' => '1.2',
                                 'Email::MessageID' => '1.2',
                                 'Email::Simple' => '1.9',
                                 'Test::More' => '0.47',
                                },
               VERSION_FROM  => 'lib/Email/MIME/Modifier.pm',
              );
