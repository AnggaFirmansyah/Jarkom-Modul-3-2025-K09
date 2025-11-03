# Di Palantir
printf "nameserver 10.68.5.2\noptions timeout:2 attempts:2\n" > /etc/resolv.conf
cat > /etc/apt/apt.conf.d/00proxy <<'EOF'
Acquire::http::Proxy  "http://10.68.5.2:3128";
Acquire::https::Proxy "http://10.68.5.2:3128";
EOF

apt update -o Acquire::ForceIPv4=true -y
apt install -y mariadb-server

# Ubah bind address agar bisa diakses dari luar
sed -i 's/^\(bind-address\s*=\s*\).*/\10.68.4.3/' /etc/mysql/mariadb.conf.d/50-server.cnf
service mariadb restart

# Setup database dan user
mariadb -u root <<'EOF'
CREATE DATABASE IF NOT EXISTS laravel_db;
DROP USER IF EXISTS 'laravel_user'@'%';
CREATE USER 'zeinkeren'@'%' IDENTIFIED BY 'nandakocak';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'zeinkeren'@'%';
FLUSH PRIVILEGES;
EOF

# Di Elendil, Isildur, Anarion
cd /var/www/resource-laravel

# Patch migration
cat > database/migrations/2023_02_08_103126_create_airings_table.php <<'EOF'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('airings', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('status');
            $table->date('start_date');
            $table->timestamps();
        });
    }
    public function down() {
        Schema::dropIfExists('airings');
    }
};
EOF

# Seeder dan konfigurasi
cat > database/seeders/airing.json <<'EOF'
{
  "data": [
    {"title": "Attack on Titan", "status": "Finished Airing", "start_date": "2013-04-07"},
    {"title": "One Piece", "status": "Currently Airing", "start_date": "1999-10-20"},
    {"title": "Jujutsu Kaisen", "status": "Finished Airing", "start_date": "2020-10-03"}
  ]
}
EOF

cat > database/seeders/AiringSeeder.php <<'EOF'
<?php
namespace Database\Seeders;
use App\Models\Airing;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;
class AiringSeeder extends Seeder {
    public function run() {
        $json = File::get(database_path('seeders/airing.json'));
        $data = json_decode($json, true);
        Airing::truncate();
        if (isset($data['data'])) {
            foreach ($data['data'] as $item) {
                Airing::create([
                    'title' => $item['title'],
                    'status' => $item['status'],
                    'start_date' => $item['start_date'],
                ]);
            }
        }
    }
}
EOF

# Update DatabaseSeeder.php
cat > database/seeders/DatabaseSeeder.php <<'EOF'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder {
    public function run() {
        $this->call([AiringSeeder::class]);
    }
}
EOF

# Konfigurasi .env
sed -i "s/DB_HOST=127.0.0.1/DB_HOST=10.68.4.3/" .env
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=laravel_db/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=zeinkeren/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=nandakocak/" .env

# Migrasi dan seeding di Elendil
php artisan migrate:fresh --seed



