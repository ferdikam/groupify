<?php

namespace App\Filament\Resources\GroupageResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ProduitsRelationManager extends RelationManager
{
    protected static string $relationship = 'groupageProduits';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('produit_id')
                     ->relationship('produit', 'nom'),
                Forms\Components\TextInput::make('moq')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('prix_achat')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('prix_transport_fournisseur')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('fret')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('prix_livraison')
                    ->numeric(),
                Forms\Components\TextInput::make('prix_vente')
                    ->required()
                    ->numeric(),

            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('nom')
            ->columns([
                Tables\Columns\TextColumn::make('moq')->numeric(),
                Tables\Columns\TextColumn::make('prix_achat')->numeric(),
                Tables\Columns\TextColumn::make('prix_transport_fournisseur')->numeric(),
                Tables\Columns\TextColumn::make('fret')->numeric(),
                Tables\Columns\TextColumn::make('prix_livraison')->numeric(),
                Tables\Columns\TextColumn::make('prix_de_revient')->numeric(),
                Tables\Columns\TextColumn::make('prix_vente')->numeric(),
                Tables\Columns\TextColumn::make('produit.nom'),
                Tables\Columns\TextColumn::make('produit.fournisseur.nom'),
            ])
            ->filters([
                //
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }
}
