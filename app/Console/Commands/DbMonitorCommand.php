<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use PDOException;

class DbMonitorCommand extends Command
{
    protected $signature = 'db:monitor {--count=1} {--timeout=5}';
    protected $description = 'Monitor database connection';

    public function handle()
    {
        $count = (int) $this->option('count');
        $timeout = (int) $this->option('timeout');

        for ($i = 0; $i < $count; $i++) {
            try {
                DB::connection()->getPdo();
                $this->info('Database connection established');
                return 0;
            } catch (PDOException $e) {
                $this->warn("Attempt {$i}: " . $e->getMessage());
                if ($i < $count - 1) {
                    sleep($timeout);
                }
            }
        }

        $this->error('Could not establish database connection');
        return 1;
    }
}
