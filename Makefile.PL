use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Modify Email::MIME Objects Easily",
               NAME          => 'Email::MIME::Modifier',
               PREREQ_PM     => {
                                 'Test::More'               => '',
                                 'Test::Deep'               => '',
                                 'Email::MIME'              => '1.7',
                                 'Email::Simple'            => '1.7',
                                 'Email::MIME::ContentType' => '',
                                 'Email::MIME::Encodings'   => '',
                                 'Email::MessageID'         => '',
                                },
               VERSION_FROM  => 'lib/Email/MIME/Modifier.pm',
              );
