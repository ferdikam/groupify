<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SouscriptionResource\Pages;
use App\Filament\Resources\SouscriptionResource\RelationManagers;
use App\Models\Souscription;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class SouscriptionResource extends Resource
{
    protected static ?string $model = Souscription::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required(),
                Forms\Components\Select::make('groupage_id')
                    ->relationship('groupage', 'nom')
                    ->required(),
                Forms\Components\TextInput::make('quantite')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('montant_total')
                    ->numeric(),
                Forms\Components\TextInput::make('avance_payee')
                    ->numeric(),
                Forms\Components\TextInput::make('solde_restant')
                    ->numeric(),
                Forms\Components\TextInput::make('statut')
                    ->required(),
                Forms\Components\DateTimePicker::make('date_livraison_souhaitee'),
                Forms\Components\Textarea::make('lieu_livraison')
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user_id')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('groupage.id')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('quantite')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('montant_total')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('avance_payee')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('solde_restant')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('statut')
                    ->searchable(),
                Tables\Columns\TextColumn::make('date_livraison_souhaitee')
                    ->dateTime()
                    ->sortable(),
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
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSouscriptions::route('/'),
            'create' => Pages\CreateSouscription::route('/create'),
            'view' => Pages\ViewSouscription::route('/{record}'),
            'edit' => Pages\EditSouscription::route('/{record}/edit'),
        ];
    }
}
