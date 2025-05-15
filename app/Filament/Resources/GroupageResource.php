<?php

namespace App\Filament\Resources;

use App\Enums\GroupageStatus;
use App\Filament\Resources\GroupageResource\Pages;
use App\Filament\Resources\GroupageResource\RelationManagers;
use App\Models\Groupage;
use App\Models\Produit;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class GroupageResource extends Resource
{
    protected static ?string $model = Groupage::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make()
                    ->schema([
                        Forms\Components\TextInput::make('nom')
                            ->required(),
                        Forms\Components\Textarea::make('description')
                            ->required()
                            ->columnSpanFull(),
                        Forms\Components\DateTimePicker::make('date_debut')
                            ->required(),
                        Forms\Components\DateTimePicker::make('date_fin')
                            ->required(),
                        Forms\Components\Select::make('statut')
                            ->options(GroupageStatus::class)
                            ->required(),
                    ])->columns(3),

                Forms\Components\Section::make()
                    ->schema([
                        Forms\Components\Repeater::make('groupageProduits')
                            ->relationship()
                            ->schema([
                                Forms\Components\Select::make('produit_id')
                                    ->options(Produit::all()->pluck('nom', 'id')),
                                Forms\Components\TextInput::make('moq')
                                    ->default(0)
                                    ->required()
                                    ->numeric(),
                                Forms\Components\TextInput::make('prix_achat')
                                    ->default(0)
                                    ->required()
                                    ->numeric()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(fn (Get $get, Set $set) =>
                                    $set(
                                        'prix_de_revient',
                                        (int)$get('prix_achat') +
                                        (int)$get('prix_transport_fournisseur') +
                                        (int)$get('fret') +
                                        (int)$get('prix_livraison')
                                    )
                                    ),
                                Forms\Components\TextInput::make('prix_transport_fournisseur')
                                    ->default(0)
                                    ->required()
                                    ->numeric()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(fn (Get $get, Set $set) =>
                                    $set(
                                        'prix_de_revient',
                                        (int)$get('prix_achat') +
                                        (int)$get('prix_transport_fournisseur') +
                                        (int)$get('fret') +
                                        (int)$get('prix_livraison')
                                    )
                                    ),
                                Forms\Components\TextInput::make('fret')
                                    ->default(0)
                                    ->required()
                                    ->numeric()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(fn (Get $get, Set $set) =>
                                    $set(
                                        'prix_de_revient',
                                        (int)$get('prix_achat') +
                                        (int)$get('prix_transport_fournisseur') +
                                        (int)$get('fret') +
                                        (int)$get('prix_livraison')
                                    )
                                    ),
                                Forms\Components\TextInput::make('prix_livraison')
                                    ->numeric()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(fn (Get $get, Set $set) =>
                                    $set(
                                        'prix_de_revient',
                                        (int)$get('prix_achat') +
                                        (int)$get('prix_transport_fournisseur') +
                                        (int)$get('fret') +
                                        (int)$get('prix_livraison')
                                    )
                                    ),
                                Forms\Components\TextInput::make('prix_de_revient')
                                    ->default(0)
                                    ->numeric()
                                    ->disabled()
                                    ->dehydrated(true),
                                Forms\Components\TextInput::make('prix_vente')
                                    ->required()
                                    ->numeric(),

                            ])

                            ->columns(3),

                    ])
                    ->columnSpanFull(),


            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nom')
                    ->searchable(),
                Tables\Columns\TextColumn::make('date_debut')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('date_fin')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('statut')
                    ->searchable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\ProduitsRelationManager::class
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListGroupages::route('/'),
            'create' => Pages\CreateGroupage::route('/create'),
            'view' => Pages\ViewGroupage::route('/{record}'),
            'edit' => Pages\EditGroupage::route('/{record}/edit'),
        ];
    }
}
