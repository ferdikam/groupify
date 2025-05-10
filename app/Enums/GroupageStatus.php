<?php

namespace App\Enums;

enum GroupageStatus
{
    case DRAFT;
    case PUBLISHED;
    case DELIVERED;
    case ARCHIVED;

    public function label(): string
    {
        return match ($this) {
            GroupageStatus::DRAFT => __('brouillon'),
            GroupageStatus::PUBLISHED => __('publié'),
            GroupageStatus::DELIVERED => __('livré'),
            GroupageStatus::ARCHIVED => __('archivé'),
        };
    }

    public function color(): string
    {
        return match ($this) {
            GroupageStatus::DRAFT => 'bg-gray-400',
            GroupageStatus::PUBLISHED => 'bg-green-400',
            GroupageStatus::DELIVERED => 'bg-blue-400',
            GroupageStatus::ARCHIVED => 'bg-yellow-400',
        };
    }
}
