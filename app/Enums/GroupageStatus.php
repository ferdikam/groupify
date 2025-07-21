<?php

namespace App\Enums;

use Filament\Support\Contracts\HasDescription;
use Filament\Support\Contracts\HasLabel;

enum GroupageStatus: string implements HasLabel, HasDescription
{
    case DRAFT = 'brouillon' ;
    case PUBLISHED = 'publié' ;
    case DELIVERED = 'livré' ;
    case ARCHIVED = 'archivé' ;

    public function color(): string
    {
        return match ($this) {
            GroupageStatus::DRAFT => 'bg-gray-400',
            GroupageStatus::PUBLISHED => 'bg-green-400',
            GroupageStatus::DELIVERED => 'bg-blue-400',
            GroupageStatus::ARCHIVED => 'bg-yellow-400',
        };
    }

    public function getDescription(): ?string
    {
        return match ($this) {
            self::DRAFT => 'This has not finished being written yet.',
            self::PUBLISHED => 'This is ready for a staff member to read.',
            self::DELIVERED => 'This has been approved by a staff member and is public on the website.',
            self::ARCHIVED => 'A staff member has decided this is not appropriate for the website.',
        };
    }

    public function getLabel(): ?string
    {
        return match ($this) {
            self::DRAFT => 'brouillon',
            self::PUBLISHED => 'publié',
            self::DELIVERED => 'livré',
            self::ARCHIVED => 'archivé',
        };
    }
}
